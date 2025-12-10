🤖 Serverless AI Voice Assistant

A complete serverless AI voice assistant that processes voice commands, converts them to text, generates AI responses, and converts responses back to speech. Built with a React + TypeScript frontend, Flask backend, and deployed on AWS Lambda using Terraform.

🌟 Features

🎤 Voice Processing: Record and process voice commands

🤖 AI Integration: OpenAI-powered intelligent responses

🌤️ Weather Information: Real-time weather data integration

🔊 Text-to-Speech: Convert AI responses to natural-sounding speech

☁️ Serverless Architecture: Fully serverless deployment on AWS

🚀 Automated Deployment: Single-command deployment pipeline

🌐 Web Interface: Modern React-based user interface

```
serverless-AI-voice-assistant/
├── ai_project/ # Frontend React/Vite TypeScript application
├── flask_file/ # Backend Python/Flask application
│ ├── ffmpeg/ # FFmpeg binaries for audio processing
│ ├── uploads/ # Voice samples and uploads directory
│ ├── Assistant2.py # Main Lambda function handler
│ ├── buildlambda.ps1 # Lambda package builder script
│ ├── requirements.txt # Python dependencies
│ └── response.wav # Sample response file
├── terraform/ # Infrastructure as Code
│ ├── main.tf # Main Terraform configuration
│ └── variables.tf # Terraform variables
├── deploy.ps1 # Main deployment script
└── README.md # This file
```


✅ Prerequisites

AWS account with CLI configured

Node.js (v16+)

Python (3.9+)

Terraform (optional — deploy script can handle it)

OpenWeather API Key (get one from OpenWeatherMap)

🚀 Installation & Deployment
Method 1 — One-Click Deployment (recommended)
# Set your OpenWeather API key as environment variable
$env:WEATHER_API_KEY = "your_openweather_api_key_here"

# Run the deployment script
.\deploy.ps1

Method 2 — Step-by-step Deployment

Clone and prepare:

git clone <your-repo-url>
cd serverless-AI-voice-assistant


Set environment variable (PowerShell):

$env:WEATHER_API_KEY = "your_api_key_here"


Run the deployment script:

.\deploy.ps1

🔧 What the Deployment Script Does

The deploy.ps1 script automates the deployment:

✅ Prerequisites check (AWS, Node, Python)

✅ AWS authentication check

🏗️ Backend build (packages Python + dependencies)

☁️ Infrastructure deployment (Terraform)

⚛️ Frontend build (React with configured API endpoint)

🌐 Frontend deployment (Netlify or manual instructions)

🏗️ Architecture Details
AWS Infrastructure (Terraform)

The Terraform code in /terraform creates:

S3 Bucket (lambda_bucket) — stores Lambda deployment package (private).

IAM Role & Policy (lambda_role) — execution role with CloudWatch & S3 access.

Lambda Function (voice_assistant) — Python 3.9 runtime, 1024MB memory, 60s timeout. Handler: Assistant2.lambda_handler.

API Gateway (voice_assistant_api) — HTTP API with CORS + proxy integration to Lambda.

Permissions — API Gateway permission to invoke Lambda; S3 object for Lambda code.

Note: I fixed the numbering and made it sequential.

🐍 Backend (Python / Flask)

Located in /flask_file:

Assistant2.py: Main Lambda handler with endpoints:

/ — Health check

/process — Process voice commands

/test-voice — Test voice functionality

Audio processing uses FFmpeg (put binaries in /flask_file/ffmpeg/). Supports multiple audio formats and handles speech-to-text / text-to-speech.

⚛️ Frontend (React / TypeScript)

Located in /ai_project:

Built with Vite + React + TypeScript

Voice recording interface, real-time response display, and audio playback controls

Uses environment variables to configure the backend API URL

🔧 Manual Deployment Steps

Run these if you prefer full manual control.

Build Lambda package

cd flask_file
.\buildlambda.ps1
cd ..


Deploy infrastructure

cd terraform
terraform init
terraform apply -var="weather_api_key=YOUR_API_KEY"
cd ..


Build Frontend

cd ai_project
npm install
npm run build
cd ..


Deploy to Netlify

Use Netlify CLI:

netlify deploy --prod --dir=dist


OR upload the dist folder via the Netlify dashboard.

📋 Environment Variables
Variable	Description	Required
WEATHER_API_KEY	OpenWeatherMap API key	Yes
VITE_API_BASE_URL	Backend API URL (frontend)	Auto-generated / set in env
🧪 Testing Your Deployment
# Test health check
curl <your-api-gateway-url>

# Example response
# {"message":"Voice Assistant Backend is running!"}

🔍 Troubleshooting
Common issues & fixes

AWS Authentication Failed

aws configure
# Enter your AWS Access Key, Secret Key, and region


FFmpeg Issues

Ensure FFmpeg binaries exist in /flask_file/ffmpeg/ and have execution permission.

Lambda Timeout

Audio processing may exceed default timeout. Set timeout to 60s or increase if needed.

CORS Errors

Confirm API Gateway CORS configuration and check VITE_API_BASE_URL in the frontend.

Logs & Monitoring

Lambda logs: CloudWatch Logs

API Gateway logs: enable access logging if necessary

Frontend logs: browser dev tools

📊 Cost Estimation

This deployment uses AWS Free Tier–eligible services:

AWS Lambda: 1M free requests / month

API Gateway: 1M free API calls / month

S3: first 5GB free

CloudWatch: basic monitoring free

Estimated monthly cost for moderate usage: <$5 (estimate; actual varies by usage).

🔄 Updating the Application

Update backend code

cd flask_file
# make changes to Assistant2.py
.\buildlambda.ps1
cd ../terraform
terraform apply


Update frontend

cd ai_project
# make changes
npm run build
# redeploy to Netlify

🗑️ Cleanup

To remove all deployed resources:

cd terraform
terraform destroy

🤝 Contributing

Fork the repo

Create a feature branch

Make changes & test thoroughly

Submit a pull request

📄 License

MIT License — see LICENSE file for details.

🙏 Acknowledgments

OpenAI for AI capabilities

AWS for serverless infrastructure

OpenWeatherMap for weather data

FFmpeg for audio processing

📞 Support

If you need help:

Check the troubleshooting section

Open a GitHub issue

Review AWS documentation for specific services

Built with ❤️ using serverless technology — Happy coding! 🚀
