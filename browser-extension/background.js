/**
 * Background service worker for GTD Article Processor
 * Handles communication and storage
 */

chrome.runtime.onInstalled.addListener(() => {
  console.log('GTD Article Processor installed');
  
  // Set default settings
  chrome.storage.sync.set({
    apiEndpoint: 'http://localhost:8000'
  });
});

// Handle messages from content scripts or popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'getSettings') {
    chrome.storage.sync.get(['apiEndpoint'], (result) => {
      sendResponse(result);
    });
    return true; // Keep channel open for async response
  }
});
