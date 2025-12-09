
param(
    [string]$WeatherApiKey = $env:WEATHER_API_KEY
)

Write-Host "Starting Complete Voice Assistant Deployment..." -ForegroundColor Green

# Check prerequisites
$commands = @("aws", "node", "python")
foreach ($cmd in $commands) {
    if (!(Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: $cmd is not installed. Please install it first." -ForegroundColor Red
        exit 1
    }
}

# Check AWS authentication
try {
    $null = aws sts get-caller-identity
} catch {
    Write-Host "ERROR: Not authenticated with AWS. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}


# Build backend
Write-Host "`nBuilding backend for Lambda..." -ForegroundColor Green
cd flask_file

# Build Lambda package
.\buildlambda.ps1

cd ..

# Deploy infrastructure with Terraform
Write-Host "`nDeploying AWS infrastructure..." -ForegroundColor 

cd terraform

# Initialize Terraform
terraform init

terraform plan

# Apply infrastructure
terraform apply -auto-approve -var="weather_api_key=$WeatherApiKey"

# Get API URL
$apiUrl = terraform output -raw api_url
Write-Host "Backend API deployed: $apiUrl" -ForegroundColor Green

cd ..

# Build frontend with API URL
Write-Host "`nBuilding frontend..." -ForegroundColor Green
cd ai_project

# Install dependencies
npm install

# Create environment file with API URL
"VITE_API_BASE_URL=$apiUrl" | Out-File -FilePath ".env.production" -Encoding UTF8

# Build frontend
npm run build

Write-Host "Frontend built successfully!" -ForegroundColor Green



# Check if Netlify CLI is installed
if (!(Get-Command netlify -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Netlify CLI..." -ForegroundColor Yellow
    npm install -g netlify-cli
}

# Deploy to Netlify
try {
    $netlifyUrl = netlify deploy --prod --dir=dist --json | ConvertFrom-Json
    Write-Host "Frontend deployed to: $($netlifyUrl.deploy_url)" -ForegroundColor Green
} catch {
    Write-Host "Netlify deployment failed. Deploy manually:" -ForegroundColor Yellow
    Write-Host "1. Go to https://app.netlify.com/" -ForegroundColor White
    Write-Host "2. Drag the 'frontend/dist' folder to Netlify" -ForegroundColor White
}

cd ..

Write-Host "`nDEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host "Backend API: $apiUrl" -ForegroundColor Cyan
if ($netlifyUrl) {
    Write-Host "Frontend URL: $($netlifyUrl.deploy_url)" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Testing your API:" -ForegroundColor Yellow
Write-Host "curl '$apiUrl'"