import json
import boto3
import speech_recognition as sr
import pyttsx3
import webbrowser
import requests
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from pydub import AudioSegment
import os
import time
import tempfile
import uuid

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configure FFmpeg path for Lambda
FFMPEG_PATH = '/opt/bin/ffmpeg'
FFPROBE_PATH = '/opt/bin/ffprobe'

# Set FFmpeg paths
AudioSegment.converter = FFMPEG_PATH
AudioSegment.ffprobe = FFPROBE_PATH

# Initialize text-to-speech engine
engine = pyttsx3.init()

reminders = []  # Store reminders

# 🔹 Converts text to speech and saves it as a WAV file
def speak_and_save(text, filename=None):
    if filename is None:
        filename = f"/tmp/response_{uuid.uuid4().hex}.wav"
    
    engine.save_to_file(text, filename)
    engine.runAndWait()
    return filename

# 🔹 Converts any audio file to WAV format
def convert_to_wav(audio_path):
    try:
        audio = AudioSegment.from_file(audio_path)
        audio = audio.set_frame_rate(16000).set_channels(1).set_sample_width(2)
        converted_path = f"/tmp/{uuid.uuid4().hex}_converted.wav"
        audio.export(converted_path, format="wav")
        return converted_path
    except Exception as e:
        print(f"Audio conversion error: {e}")
        return None

# 🔹 Fetches weather data
def get_weather(city):
    API_KEY = os.environ.get('WEATHER_API_KEY', 'your_openweather_api_key')
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
    try:
        response = requests.get(url)
        weather_data = response.json()
        if weather_data["cod"] == 200:
            temperature = weather_data["main"]["temp"]
            description = weather_data["weather"][0]["description"]
            return f"The temperature in {city} is {temperature} degrees Celsius with {description}."
        else:
            return "Sorry, I couldn't find the weather for that location."
    except Exception as e:
        return f"Unable to fetch weather data. Error: {e}"

# 🔹 Stores a reminder
def set_reminder(task, time_str):
    reminders.append({"task": task, "time": time_str})
    return f"Reminder set for {task} at {time_str}."

# 🔹 Checks and triggers reminders
def check_reminders():
    current_time = datetime.now().strftime("%H:%M")
    for reminder in reminders:
        if reminder["time"] == current_time:
            reminders.remove(reminder)
            return f"Reminder: {reminder['task']}"
    return None

# 🔹 Performs a Google search
def perform_web_search(query):
    # For Lambda, we return the search URL instead of opening browser
    search_url = f"https://www.google.com/search?q={query}"
    return f"I would search for {query}. Here's the URL: {search_url}"

# 🎤 **Processes Commands from Speech Recognition**
def assistant_command(command):
    command = command.lower()

    if "weather in" in command:
        city = command.split("weather in", 1)[1].strip()
        return get_weather(city)

    elif "set a reminder" in command:
        return "Please specify the task and time in the format: set a reminder [task] at [time]"

    elif "search for" in command or "look up" in command:
        query = command.split("search for", 1)[1].strip() if "search for" in command else command.split("look up", 1)[1].strip()
        return perform_web_search(query)

    elif "exit" in command or "quit" in command:
        return "Goodbye!"
    elif "hello" in command or "hi" in command:
        return "Hey, I am your assistant, how can I help you today?"
    elif "how are you doing" in command or "how are you" in command:
        return "I am good, hope you are having a good day"
    else:
        return "I'm not sure how to handle that command yet."

# 🎤 **Processes Voice Commands and Returns Audio Response**
@app.route('/run_code', methods=['POST'])
def run_code():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
        
    command = data.get("command", "").lower()

    if not command:
        return jsonify({"error": "No command provided."}), 400

    response = assistant_command(command)

    # 🔊 Convert response to speech and return file path
    response_audio_path = speak_and_save(response)
    
    # Return the audio file path (will be served by Lambda)
    return jsonify({
        "message": response,
        "audio_url": f"/audio?file={os.path.basename(response_audio_path)}"
    })

# 🎤 **Handles Audio File Uploads & Speech Recognition**
@app.route('/process_audio', methods=['POST'])
def process_audio():
    if 'audio' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400

    audio_file = request.files['audio']
    
    # Save to temporary file
    temp_audio_path = f"/tmp/{uuid.uuid4().hex}_{audio_file.filename}"
    audio_file.save(temp_audio_path)

    # Convert audio to WAV
    converted_path = convert_to_wav(temp_audio_path)
    if not converted_path:
        # Clean up
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)
        return jsonify({"error": "Audio conversion failed"}), 400

    recognizer = sr.Recognizer()

    try:
        with sr.AudioFile(converted_path) as source:
            audio_data = recognizer.record(source)
        text = recognizer.recognize_google(audio_data)
        
        # Process command
        response = assistant_command(text)
        
        # Convert response to speech
        response_audio_path = speak_and_save(response)
        
        # Return response
        return jsonify({
            "transcribed_text": text,
            "response": response,
            "audio_url": f"/audio?file={os.path.basename(response_audio_path)}"
        })

    except sr.UnknownValueError:
        return jsonify({"error": "Could not understand the audio"}), 400
    except sr.RequestError as e:
        return jsonify({"error": f"Speech recognition service error: {e}"}), 500
    finally:
        # Clean up temporary files
        for file_path in [temp_audio_path, converted_path]:
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                except:
                    pass

# 🔈 Serve audio files
@app.route('/audio', methods=['GET'])
def get_audio():
    filename = request.args.get('file')
    if not filename:
        return jsonify({"error": "No filename provided"}), 400
    
    file_path = f"/tmp/{filename}"
    if not os.path.exists(file_path):
        return jsonify({"error": "Audio file not found"}), 404
    
    try:
        with open(file_path, 'rb') as f:
            audio_data = f.read()
        
        # Clean up the file after sending
        os.remove(file_path)
        
        return audio_data, 200, {'Content-Type': 'audio/wav'}
    except Exception as e:
        return jsonify({"error": f"Error reading audio file: {e}"}), 500

@app.route('/')
def home():
    return jsonify({"message": "Voice Assistant API is running"})

# Lambda handler
def lambda_handler(event, context):
    from aws_wsgi import make_lambda_handler
    
    # This converts API Gateway events to WSGI
    handler = make_lambda_handler(app)
    return handler(event, context)

# For local development
if __name__ == "__main__":
    app.run(debug=True)