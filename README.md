# 🤖 Serverless AI Voice Assistant

A complete serverless AI voice assistant that processes voice commands, converts them to text, generates AI responses, and converts responses back to speech. Built with React/TypeScript frontend, Flask backend, and deployed on AWS Lambda using Terraform.

🌟 Features
🎤 Voice Processing: Record and process voice commands
🤖 AI Integration: OpenAI-powered intelligent responses
🌤️ Weather Information: Real-time weather data integration
🔊 Text-to-Speech: Convert AI responses to natural-sounding speech
☁️ Serverless Architecture: Fully serverless deployment on AWS
🚀 Automated Deployment: Single-command deployment pipeline
🌐 Web Interface: Modern React-based user interface

📁 Project Structure
text
serverless-AI-voice-assistant/
├── 📁 ai_project/                 # Frontend React/Vite TypeScript application
├── 📁 flask_file/                 # Backend Python/Flask application
│   ├── 📁 ffmpeg/                 # FFmpeg binaries for audio processing
│   ├── 📁 uploads/                # Voice samples and uploads directory
│   ├── Assistant2.py              # Main Lambda function handler
│   ├── buildlambda.ps1            # Lambda package builder script
│   ├── requirements.txt           # Python dependencies
│   └── response.wav               # Sample response file
├── 📁 terraform/                  # Infrastructure as Code
│   ├── main.tf                    # Main Terraform configuration
│   └── variables.tf               # Terraform variables
├── deploy.ps1                     # Main deployment script
└── README.md                      # This file
🚀 Quick Start

Prerequisites

AWS Account with CLI configured
Node.js (v16+)
Python (3.9+)
Terraform (optional - included in deploy script)
OpenWeather API Key (get one from OpenWeatherMap)

#Installation & Deployment

Method 1: One-Click Deployment (Recommended)
powershell

### Set your OpenWeather API key as environment variable
$env:WEATHER_API_KEY = "your_openweather_api_key_here"

### Run the deployment script
.\deploy.ps1
Method 2: Step-by-Step Deployment
Clone and prepare:

bash
git clone <your-repo-url>
cd serverless-AI-voice-assistant
Set environment variable:

powershell
$env:WEATHER_API_KEY = "your_api_key_here"
Run the deployment:

powershell
.\deploy.ps1
What the Deployment Script Does
The deploy.ps1 script automates the entire deployment process:

✅ Prerequisites Check - Verifies AWS, Node.js, Python installations
✅ AWS Authentication Check - Ensures you're logged into AWS CLI
🏗️ Backend Build - Packages Python code with dependencies
☁️ Infrastructure Deployment - Uses Terraform to create AWS resources
⚛️ Frontend Build - Builds React app with API endpoint configured
🌐 Frontend Deployment - Deploys to Netlify (or provides manual instructions)

🏗️ Architecture Details
AWS Infrastructure (Terraform)
The Terraform code in /terraform creates:

1. S3 Bucket (lambda_bucket)
Stores the Lambda deployment package
Private bucket with proper ownership controls

2. IAM Role & Policy (lambda_role)
Execution role for Lambda function
Permissions for CloudWatch logging and S3 access

3. Lambda Function (voice_assistant)
Python 3.9 runtime with 1024MB memory
60-second timeout for audio processing
Environment variables for API keys
Handler: Assistant2.lambda_handler

4. API Gateway (voice_assistant_api)
HTTP API with CORS enabled
Automatic deployment
Proxy integration with Lambda

6. Permissions
API Gateway permission to invoke Lambda
S3 object for Lambda code storage

Backend(Python/Flask)
Located in /flask_file:
Assistant2.py: Main Lambda handler with endpoints:
/: Health check
/process: Process voice commands
/test-voice: Test voice functionality

Audio Processing:
Uses FFmpeg for audio conversion
Supports multiple audio formats
Text-to-speech and speech-to-text conversion
Frontend (React/TypeScript)

Located in /ai_project:
Built with Vite + React + TypeScript
Voice recording interface
Real-time response display
Audio playback controls
Environment-based API configuration


🔧 Manual Deployment Steps
If you prefer to deploy manually:

1. Build Lambda Package
powershell
cd flask_file
.\buildlambda.ps1
cd ..

3. Deploy Infrastructure
powershell
cd terraform
terraform init
terraform apply -var="weather_api_key=YOUR_API_KEY"
cd ..

5. Build Frontend
powershell
cd ai_project
npm install
npm run build
cd ..

7. Deploy to Netlify
Either use Netlify CLI: netlify deploy --prod --dir=dist

Or drag the dist folder to Netlify dashboard

📋 Environment Variables
Variable	Description	Required
WEATHER_API_KEY	OpenWeatherMap API key	Yes
VITE_API_BASE_URL	Backend API URL	Auto-generated
🧪 Testing Your Deployment
After deployment, test your API:

bash
# Test health check
curl <your-api-gateway-url>

# Example response
{"message":"Voice Assistant Backend is running!"}
🔍 Troubleshooting
Common Issues
AWS Authentication Failed

bash
aws configure
# Enter your AWS Access Key, Secret Key, and region
FFmpeg Issues

Ensure FFmpeg binaries are in /flask_file/ffmpeg/
Verify execution permissions on FFmpeg files
Lambda Timeout
Audio processing might exceed default timeout
Increased to 60 seconds in configuration
CORS Errors
API Gateway CORS is configured
Check frontend API URL configuration

Logs & Monitoring
Lambda Logs: Check CloudWatch Logs in AWS Console
API Gateway Logs: Enable access logging if needed
Frontend Logs: Browser developer console

📊 Cost Estimation
This deployment uses AWS Free Tier eligible services:

AWS Lambda: 1M free requests/month
API Gateway: 1M free API calls/month
S3: First 5GB free
CloudWatch: Basic monitoring free
Estimated monthly cost for moderate usage: < $5

🔄 Updating the Application
Update Backend Code:

powershell
cd flask_file
# Make changes to Assistant2.py
.\buildlambda.ps1
cd ../terraform
terraform apply
Update Frontend:

powershell
cd ai_project
# Make changes
npm run build
# Redeploy to Netlify
🗑️ Cleanup
To remove all deployed resources:

powershell
cd terraform
terraform destroy

🤝 Contributing
Fork the repository
Create a feature branch
Make your changes
Test thoroughly

Submit a pull request

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
OpenAI for AI capabilities
AWS for serverless infrastructure
OpenWeatherMap for weather data
FFmpeg for audio processing

📞 Support
For issues, questions, or contributions:
Check the troubleshooting section
Open a GitHub issue
Review AWS documentation for specific services

Happy Coding! 🚀
Built with ❤️ using cutting-edge serverless technology

