/**
 * Web Notifications Service
 * Uses the Web Notifications API to send browser notifications
 */

class NotificationService {
  constructor() {
    this.permission = null
    this.checkPermission()
  }

  /**
   * Check current notification permission status
   */
  checkPermission() {
    if (!('Notification' in window)) {
      console.warn('This browser does not support notifications')
      this.permission = 'unsupported'
      return false
    }

    this.permission = Notification.permission
    return this.permission === 'granted'
  }

  /**
   * Request notification permission from the user
   * @returns {Promise<boolean>} True if permission granted
   */
  async requestPermission() {
    if (!('Notification' in window)) {
      console.warn('This browser does not support notifications')
      return false
    }

    // Update permission status
    this.checkPermission()

    if (Notification.permission === 'granted') {
      this.permission = 'granted'
      return true
    }

    if (Notification.permission === 'denied') {
      this.permission = 'denied'
      console.warn('Notification permission was denied by user. Cannot request again.')
      return false
    }

    // Request permission (only works with user gesture in some browsers)
    try {
      const permission = await Notification.requestPermission()
      this.permission = permission
      return permission === 'granted'
    } catch (error) {
      // Some browsers require a user gesture to request permission
      console.warn('Cannot request notification permission:', error.message)
      this.permission = Notification.permission
      return false
    }
  }

  /**
   * Send a notification
   * @param {string} title - Notification title
   * @param {NotificationOptions} options - Notification options
   * @returns {Notification|null} The notification object or null if failed
   */
  async notify(title, options = {}) {
    console.log('NotificationService.notify called:', { title, options, permission: this.permission })
    
    // Check current permission status (it may have changed)
    this.checkPermission()
    
    // If permission is denied, don't try to request it again (requires user gesture)
    if (this.permission === 'denied') {
      console.warn('Cannot send notification: permission was denied by user')
      return null
    }
    
    // If permission is not granted, try to request it (only works if there was a user gesture)
    if (this.permission !== 'granted') {
      console.log('Permission not granted, attempting to request...')
      try {
        const granted = await this.requestPermission()
        if (!granted) {
          console.warn('Cannot send notification: permission not granted')
          return null
        }
        console.log('Permission granted')
      } catch (error) {
        // Permission request failed (likely no user gesture)
        console.warn('Cannot request notification permission (requires user gesture):', error.message)
        return null
      }
    }

    // Default options - make important notifications require interaction
    const defaultOptions = {
      icon: '/favicon.ico',
      badge: '/favicon.ico',
      tag: 'gtd-wizard',
      requireInteraction: options.requireInteraction !== undefined ? options.requireInteraction : true, // Default to true for important notifications
      silent: false,
      ...options
    }

    try {
      const notification = new Notification(title, defaultOptions)
      
      // Auto-close after 10 seconds if not requiring interaction (longer for important notifications)
      if (!defaultOptions.requireInteraction) {
        setTimeout(() => {
          notification.close()
        }, 10000)
      }

      // Handle click to focus window
      notification.onclick = () => {
        window.focus()
        notification.close()
      }

      return notification
    } catch (error) {
      console.error('Error showing notification:', error)
      return null
    }
  }

  /**
   * Send a notification for advice being ready
   * @param {string} persona - Persona name
   * @param {string} question - The question asked
   */
  async notifyAdviceReady(persona, question) {
    console.log('notifyAdviceReady called:', { persona, question })
    const result = await this.notify('🤖 Advice Ready', {
      body: `Your advice from ${persona} is ready!`,
      tag: `advice-${persona}`,
      data: {
        type: 'advice-ready',
        persona,
        question
      }
    })
    console.log('notifyAdviceReady result:', result)
    return result
  }

  /**
   * Send a notification for a new suggestion
   * @param {string} title - Suggestion title
   */
  async notifyNewSuggestion(title) {
    return this.notify('💡 New AI Suggestion', {
      body: title,
      tag: 'ai-suggestion',
      data: {
        type: 'suggestion',
        title
      }
    })
  }

  /**
   * Send a notification for habit reminder
   * @param {string} habitName - Habit name
   */
  async notifyHabitReminder(habitName) {
    return this.notify('🔄 Habit Reminder', {
      body: `Don't forget: ${habitName}`,
      tag: `habit-${habitName}`,
      data: {
        type: 'habit-reminder',
        habitName
      }
    })
  }

  /**
   * Check if notifications are supported and enabled
   * @returns {boolean}
   */
  isSupported() {
    return 'Notification' in window && this.permission === 'granted'
  }

  /**
   * Get permission status
   * @returns {string} 'granted', 'denied', 'default', or 'unsupported'
   */
  getPermissionStatus() {
    return this.permission || 'default'
  }
}

// Export singleton instance
export const notificationService = new NotificationService()
