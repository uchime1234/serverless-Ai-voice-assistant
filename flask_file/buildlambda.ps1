# Build Lambda deployment package
Write-Host "Building Lambda deployment package..." -ForegroundColor Green

# Create package directory
Remove-Item -Path "package" -Recurse -ErrorAction Ignore
New-Item -ItemType Directory -Path "package" -Force

# Copy Python files
Copy-Item "Assistant2.py" "package/"
Copy-Item "requirements.txt" "package/"

# Install dependencies
pip install -r requirements.txt -t package/

# Copy FFmpeg binaries to bin folder for Lambda
New-Item -ItemType Directory -Path "package/bin" -Force
Copy-Item "ffmpeg/ffmpeg" "package/bin/"
Copy-Item "ffmpeg/ffprobe" "package/bin/"

# Create zip file
Compress-Archive -Path "package/*" -DestinationPath "lambda-deployment-package.zip" -Force

Write-Host "Lambda deployment package created: lambda-deployment-package.zip" -ForegroundColor Green