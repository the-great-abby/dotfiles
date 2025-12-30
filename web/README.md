# GTD Wizard Web Interface

A modern web interface for the GTD Wizard system, built with Svelte and FastAPI.

## Quick Start

### Prerequisites

- Python 3.8+
- Node.js 18+
- GTD system installed (bash scripts)

### Setup

1. **Backend**:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

2. **Frontend** (new terminal):
```bash
cd frontend
npm install
npm run dev
```

3. **Access**: http://localhost:5173

## Documentation

- [Systemd & Nginx Deployment Guide](./README-DEPLOYMENT.md) - **Recommended for production**
- [Deployment Guide](../docs/WEB_WIZARD_DEPLOYMENT_GUIDE.md) - All deployment options
- [Integration Guide](../docs/WEB_WIZARD_INTEGRATION.md)
- [Design Document](../docs/WEB_WIZARD_INTERFACE_DESIGN.md)

## Features

- ✅ Capture items to inbox
- ✅ Process inbox items
- ✅ Manage tasks
- ✅ Manage projects
- ✅ Real-time status updates (WebSocket)
- ✅ Responsive design
- ✅ Full compatibility with CLI wizard

## Architecture

- **Backend**: FastAPI (Python)
- **Frontend**: Svelte + Vite
- **Integration**: Subprocess calls to GTD bash scripts

## License

Same as main repository.




