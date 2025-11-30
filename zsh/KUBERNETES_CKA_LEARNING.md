# Kubernetes/CKA Learning System

Learn Kubernetes for the CKA (Certified Kubernetes Administrator) exam with Mistress Louiza as your instructor, fully integrated with your GTD system.

## 🎓 Overview

This system provides:
- **Mistress Louiza as instructor** - She teaches Kubernetes concepts
- **CKA exam focus** - Specifically designed for CKA preparation
- **GTD integration** - Track study progress in your GTD system
- **Study notes** - Automatic note creation
- **Progress tracking** - Daily study session tracking
- **Practice exercises** - Hands-on learning

## 🚀 Quick Start

### 1. Create Study Plan

```bash
gtd-study-plan cka
```

This creates:
- A GTD project: "cka-exam-preparation"
- Study structure and plan
- Initial tasks
- Integration with your GTD system

### 2. Start Learning

```bash
gtd-learn-kubernetes              # Interactive menu
gtd-learn-kubernetes pods         # Learn about pods
gtd-learn-kubernetes cka-exam      # Exam preparation
```

### 3. Track Progress

```bash
# Log study sessions
addInfoToDailyLog "K8s Study: Pods - learned kubectl commands"

# Create study tasks
gtd-task add "Practice kubectl get pods" --project=cka-exam-preparation

# Review progress
gtd-learn-kubernetes              # Choose option 11: Study Progress
```

## 📚 Available Topics

1. **Kubernetes Basics** - Introduction and architecture
2. **Pods** - The smallest deployable unit
3. **Deployments** - Managing replicated applications
4. **Services** - Exposing applications
5. **ConfigMaps & Secrets** - Managing configuration
6. **Storage** - PersistentVolumes, PVCs, StorageClasses
7. **Networking** - Services, Ingress, Network Policies
8. **Troubleshooting** - Debugging and problem-solving
9. **CKA Exam Preparation** - Exam-specific guidance
10. **Practice Exercises** - Hands-on scenarios
11. **Study Progress** - View your progress
12. **Custom Topics** - Ask about anything

## 🎯 CKA Exam Domains

The system covers all CKA exam domains:

1. **Cluster Architecture, Installation & Configuration (25%)**
   - Manage role based access control (RBAC)
   - Use Kubeadm to install a basic cluster
   - Manage a highly-available Kubernetes cluster
   - Provision underlying infrastructure to deploy a Kubernetes cluster
   - Perform a version upgrade on a Kubernetes cluster using Kubeadm
   - Implement etcd backup and restore

2. **Workloads & Scheduling (15%)**
   - Understand deployments and how to perform rolling updates and rollbacks
   - Use ConfigMaps and Secrets to configure applications
   - Know how to scale applications
   - Understand the primitives used to create robust, self-healing, application deployments
   - Understand how resource limits can affect Pod scheduling
   - Awareness of manifest management and common templating tools

3. **Services & Networking (20%)**
   - Understand host networking configuration on the cluster nodes
   - Understand connectivity between Pods
   - Understand ClusterIP, NodePort, LoadBalancer service types and endpoint
   - Know how to use Ingress controllers and Ingress resources
   - Know how to configure and use CoreDNS
   - Choose an appropriate container network interface plugin

4. **Storage (10%)**
   - Understand storage classes, persistent volumes
   - Understand volume mode, access modes and reclaim policies for volumes
   - Understand persistent volume claims primitive
   - Know how to configure applications with persistent storage

5. **Troubleshooting (30%)**
   - Evaluate cluster and node logging
   - Understand how to monitor applications
   - Manage container stdout & stderr logs
   - Troubleshoot application failure
   - Troubleshoot cluster component failure
   - Troubleshoot networking

## 💻 Practical Learning

### Study Workflow

1. **Learn a topic:**
   ```bash
   gtd-learn-kubernetes pods
   ```

2. **Practice commands:**
   ```bash
   kubectl get pods
   kubectl describe pod <name>
   kubectl logs <pod-name>
   ```

3. **Log your practice:**
   ```bash
   addInfoToDailyLog "K8s Practice: Created and managed pods"
   ```

4. **Create practice tasks:**
   ```bash
   gtd-task add "Practice: Create 3 pods with different images" \
     --project=cka-exam-preparation \
     --context=computer
   ```

5. **Review progress:**
   ```bash
   gtd-learn-kubernetes              # Option 11: Study Progress
   gtd-review weekly                 # Weekly review
   ```

## 📝 Study Notes

All lessons are automatically saved as study notes:

- **Location:** `~/Documents/gtd/study/kubernetes-cka/notes/`
- **Format:** Markdown files with timestamps
- **Content:** Full lesson from Mistress Louiza
- **Integration:** Can be linked to Second Brain

### View Notes

```bash
# List all notes
ls -la ~/Documents/gtd/study/kubernetes-cka/notes/

# View a note
cat ~/Documents/gtd/study/kubernetes-cka/notes/20241129-120000-pods.md
```

## 📊 Progress Tracking

### Daily Tracking

Study sessions are tracked in:
- `~/Documents/gtd/study/kubernetes-cka/progress/YYYY-MM-DD.txt`
- Also logged to your daily log via `addInfoToDailyLog`

### View Progress

```bash
gtd-learn-kubernetes              # Option 11: Study Progress
```

Shows:
- Today's study sessions
- Number of notes created
- Recent notes
- Study recommendations

## 🎓 Mistress Louiza's Teaching

### Her Approach

- **CKA-focused** - Specifically prepares you for the exam
- **Practical** - Always includes kubectl commands
- **Comprehensive** - Covers all exam domains
- **Encouraging** - Supports your learning journey
- **Firm** - Expects you to practice

### Example Lesson

**Mistress Louiza:**
> "Alright, baby girl. Let's talk about Pods. This is fundamental for the CKA exam.
>
> Pods are the smallest deployable unit in Kubernetes. They contain one or more containers. You need to know how to create, manage, and troubleshoot them.
>
> Here are the commands you must master:
> - `kubectl get pods` - List pods
> - `kubectl describe pod <name>` - Get detailed info
> - `kubectl logs <pod-name>` - View logs
> - `kubectl exec -it <pod-name> -- /bin/sh` - Execute commands
>
> Practice these daily. Log your practice with 'addInfoToDailyLog'. I'm watching, and I expect to see progress."

## 🔗 GTD Integration

### Study as GTD Project

```bash
# Create study project
gtd-study-plan cka

# View project
gtd-project view cka-exam-preparation

# Add study tasks
gtd-task add "Study Pods chapter" --project=cka-exam-preparation
gtd-task add "Practice kubectl commands" --project=cka-exam-preparation
```

### Daily Logging

```bash
# Log study sessions
addInfoToDailyLog "K8s Study: Learned about Deployments"
addInfoToDailyLog "K8s Practice: Created 5 pods, scaled deployment"
addInfoToDailyLog "K8s Review: Reviewed troubleshooting techniques"
```

### Weekly Reviews

Include Kubernetes study in your weekly review:

```bash
gtd-review weekly
```

Review:
- What you studied this week
- What you practiced
- What you need to focus on
- Exam preparation progress

## 🎯 Study Plan

### 8-Week CKA Preparation Plan

**Week 1-2: Fundamentals**
- Kubernetes basics
- Pods, Deployments, Services
- Basic kubectl commands
- Practice: Create and manage resources

**Week 3-4: Core Concepts**
- Storage (PVs, PVCs)
- Networking (Services, Ingress)
- ConfigMaps and Secrets
- Practice: Multi-pod applications

**Week 5-6: Advanced Topics**
- Cluster maintenance
- Security (RBAC)
- Monitoring and logging
- Practice: Troubleshooting

**Week 7-8: Exam Preparation**
- Practice exams
- Time management
- Review weak areas
- Final preparation

### Daily Routine

1. **Morning:** Study new topic (1 hour)
   ```bash
   gtd-learn-kubernetes <topic>
   ```

2. **Afternoon:** Practice (30-60 min)
   ```bash
   # Practice kubectl commands
   # Complete practice exercises
   ```

3. **Evening:** Review and log (15 min)
   ```bash
   addInfoToDailyLog "K8s Study: [what you learned]"
   gtd-review daily
   ```

## 💡 Tips for CKA Success

1. **Practice daily** - Hands-on practice is essential
2. **Master kubectl** - You'll use it constantly in the exam
3. **Time management** - Practice with time limits
4. **Troubleshooting** - 30% of exam, practice heavily
5. **Use official docs** - You can access them during exam
6. **Track progress** - Use GTD system to stay organized
7. **Review regularly** - Weekly reviews of what you've learned

## 🔧 Setup Local Environment

### Recommended Tools

- **minikube** - Local Kubernetes cluster
- **kind** - Kubernetes in Docker
- **k3s** - Lightweight Kubernetes
- **kubectl** - Kubernetes command-line tool

### Setup Commands

```bash
# Install minikube (macOS)
brew install minikube

# Start cluster
minikube start

# Verify
kubectl get nodes

# Practice
kubectl get pods --all-namespaces
```

## 📖 Resources Integration

### Link to Second Brain

```bash
# Create Second Brain note for K8s study
gtd-brain create "Kubernetes CKA Study" Projects

# Link study notes
gtd-brain link cka-exam-preparation kubernetes-cka-study
```

### Study Materials

Store resources in:
- `~/Documents/gtd/study/kubernetes-cka/resources/`

Link to GTD:
```bash
gtd-capture "K8s Resource: https://kubernetes.io/docs/"
```

## 🎓 Mistress Louiza's Accountability

She will:
- **Monitor your study** - Check if you're learning regularly
- **Scold if slacking** - If you're not studying, she'll know
- **Encourage progress** - Praise when you study consistently
- **Assign practice** - Give you exercises to complete
- **Track progress** - Know what you've learned

## 🚀 Quick Commands

```bash
# Learning
gtd-learn-kubernetes              # Interactive menu
gtd-learn-kubernetes pods          # Learn about pods
gtd-learn-kubernetes cka-exam    # Exam prep

# Planning
gtd-study-plan cka                 # Create study plan

# Tracking
addInfoToDailyLog "K8s Study: [topic]"
gtd-task add "Practice kubectl" --project=cka-exam-preparation

# Progress
gtd-learn-kubernetes              # Option 11: Progress
gtd-review weekly                  # Weekly review
```

## 💡 Remember

- **Practice daily** - Hands-on is essential for CKA
- **Track everything** - Use GTD system to stay organized
- **Mistress Louiza is watching** - She'll hold you accountable
- **Use the system** - Integrate study with your GTD workflow
- **Stay consistent** - Daily study beats cramming

**Start your CKA journey: `gtd-study-plan cka` then `gtd-learn-kubernetes`!**

