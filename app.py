from flask import Flask, render_template, request, redirect, url_for, send_file, flash
import os
from pymongo import MongoClient
from gridfs import GridFS
from PIL import Image
import subprocess
import json
from bson.objectid import ObjectId
import io

app = Flask(__name__)

jupyter_path = os.getenv('JUPYTER_PATH')

# connect to MongoDB
client = MongoClient(os.getenv('MONGO_URI'))
db = client['deforestation_db']
fs = GridFS(db)

@app.route('/')
def index():
    return render_template('index.html')

def run_notebook(area, start_date, end_date):
    # wipe image_ids.json
    with open('image_ids.json', 'w') as f:
        f.write('{}')

    notebook_path = "deforestation_detection.ipynb"
    output_path = "/app/deforestation_detection.nbconvert.ipynb"
    
    command = f"{jupyter_path} nbconvert --to notebook --execute {notebook_path} --output {output_path} --ExecutePreprocessor.kernel_name=python3 --ExecutePreprocessor.timeout=10000"

    # set environment variables to pass to the notebook
    env = {
        'AREA': area,
        'START_DATE': start_date,
        'END_DATE': end_date,
    }

    subprocess.run(command, shell=True, env={**os.environ, **env}, capture_output=True, text=True, timeout=3600)

    # get image IDs
    if not os.path.exists('image_ids.json') or os.path.getsize('image_ids.json') == 0:
        raise ValueError("The image_ids.json file is missing or empty")
    with open('image_ids.json', 'r') as f:
        image_ids = json.load(f)
    return image_ids["start_image_id"], image_ids["end_image_id"], image_ids["clustered_image_id"]

@app.route('/submit', methods=['POST'])
def submit():
    area = request.form['area']
    start_date = request.form['start_date']
    end_date = request.form['end_date']
    try:
        # trigger Jupyter notebook
        start_image_id, end_image_id, clustered_image_id = run_notebook(area, start_date, end_date)
        return redirect(url_for('result', 
                                start_image_id=start_image_id, 
                                end_image_id=end_image_id, 
                                clustered_image_id=clustered_image_id))
    except ValueError as e:
        flash(str(e))
        return redirect(url_for('error'))
    
@app.route('/result')
def result():
    start_image_id = request.args.get('start_image_id')
    end_image_id = request.args.get('end_image_id')
    clustered_image_id = request.args.get('clustered_image_id')
    
    return render_template('result.html', 
                           start_image_id=start_image_id, 
                           end_image_id=end_image_id, 
                           clustered_image_id=clustered_image_id)

@app.route('/error')
def error():
    return render_template('error.html')

@app.route('/download_nbconvert')
def download_nbconvert():
    try:
        return send_file('deforestation_detection.nbconvert.ipynb', as_attachment=True)
    except Exception as e:
        return str(e)

# get image from MongoDB
@app.route('/image/<image_id>')
def get_image(image_id):
    print("fetching image with image ID:", image_id)
    grid_out = fs.get(ObjectId(image_id))
    return send_file(io.BytesIO(grid_out.read()), mimetype='image/png')

if __name__ == '__main__':
    app.run(debug=True)