#!/bin/bash
# Quick start script for GTD Wizard Web Interface

set -e

echo "🧙 Starting GTD Wizard Web Interface..."
echo ""

# Check if we're in the right directory
if [[ ! -d "backend" ]] || [[ ! -d "frontend" ]]; then
    echo "❌ Error: Please run this script from the web/ directory"
    exit 1
fi

# Start backend
echo "📦 Starting backend..."
cd backend

if [[ ! -d "venv" ]]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

if [[ ! -f "venv/bin/python" ]]; then
    echo "❌ Error: Virtual environment setup failed"
    exit 1
fi

echo "Installing/updating dependencies..."
pip install -q -r requirements.txt

echo "✅ Backend ready"
echo ""

# Start frontend (in background)
cd ../frontend

if [[ ! -d "node_modules" ]]; then
    echo "📦 Installing frontend dependencies..."
    npm install
fi

echo "✅ Frontend ready"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting servers..."
echo ""
echo "Backend:  http://localhost:8000"
echo "Frontend: http://localhost:5173"
echo "API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop both servers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start backend in background
cd ../backend
source venv/bin/activate
python main.py &
BACKEND_PID=$!

# Start frontend
cd ../frontend
npm run dev &
FRONTEND_PID=$!

# Wait for both processes
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM

wait





