const API_BASE = '/api'

export const api = {
  async getMenu() {
    const response = await fetch(`${API_BASE}/menu`)
    if (!response.ok) throw new Error('Failed to fetch menu')
    return response.json()
  },

  async getStatus() {
    const response = await fetch(`${API_BASE}/status`)
    if (!response.ok) throw new Error('Failed to fetch status')
    return response.json()
  },

  async captureItem(item) {
    const response = await fetch(`${API_BASE}/capture`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item)
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to capture item')
    }
    return response.json()
  },

  async getInbox() {
    const response = await fetch(`${API_BASE}/inbox`)
    if (!response.ok) throw new Error('Failed to fetch inbox')
    return response.json()
  },

  async processInboxItem(itemId, action) {
    const response = await fetch(`${API_BASE}/inbox/${itemId}/process`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(action)
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to process item')
    }
    return response.json()
  },

  async deleteInboxItem(itemId) {
    const response = await fetch(`${API_BASE}/inbox/${itemId}`, {
      method: 'DELETE'
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to delete item')
    }
    return response.json()
  },

  async getTasks(priority, status) {
    const params = new URLSearchParams()
    if (priority) params.append('priority', priority)
    if (status) params.append('status', status)
    const response = await fetch(`${API_BASE}/tasks?${params}`)
    if (!response.ok) throw new Error('Failed to fetch tasks')
    return response.json()
  },

  async createTask(task) {
    const response = await fetch(`${API_BASE}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(task)
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to create task')
    }
    return response.json()
  },

  async completeTask(taskId) {
    const response = await fetch(`${API_BASE}/tasks/${taskId}/complete`, {
      method: 'POST'
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to complete task')
    }
    return response.json()
  },

  async getProjects() {
    const response = await fetch(`${API_BASE}/projects`)
    if (!response.ok) throw new Error('Failed to fetch projects')
    return response.json()
  },

  async getAdviceResults(statusFilter) {
    const params = new URLSearchParams()
    if (statusFilter) params.append('status_filter', statusFilter)
    const response = await fetch(`${API_BASE}/advice-results?${params}`)
    if (!response.ok) throw new Error('Failed to fetch advice results')
    return response.json()
  },

  async getAdviceResult(resultId) {
    const response = await fetch(`${API_BASE}/advice-results/${resultId}`)
    if (!response.ok) throw new Error('Failed to fetch advice result')
    return response.json()
  },

  async markAdviceReviewed(resultId) {
    const response = await fetch(`${API_BASE}/advice-results/${resultId}/review`, {
      method: 'POST'
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to mark as reviewed')
    }
    return response.json()
  },

  async deleteAdviceResult(resultId) {
    const response = await fetch(`${API_BASE}/advice-results/${resultId}`, {
      method: 'DELETE'
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to delete advice result')
    }
    return response.json()
  },

  async getDailyReviewData(reviewType) {
    const params = new URLSearchParams()
    if (reviewType) params.append('review_type', reviewType)
    const response = await fetch(`${API_BASE}/reviews/daily?${params}`)
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to fetch review data')
    }
    return response.json()
  },

  async submitDailyReview(review) {
    const response = await fetch(`${API_BASE}/reviews/daily`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(review)
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to submit review')
    }
    return response.json()
  },

  async completeHabit(habitName) {
    const response = await fetch(`${API_BASE}/habits/${encodeURIComponent(habitName)}/complete`, {
      method: 'POST'
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to complete habit')
    }
    return response.json()
  }
}





