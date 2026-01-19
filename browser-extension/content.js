/**
 * Content script to extract page content
 * Runs on all pages to extract article content
 */

(function() {
  'use strict';

  /**
   * Extract clean text content from the page
   */
  function extractPageContent() {
    const content = {
      url: window.location.href,
      title: document.title,
      text: '',
      html: '',
      timestamp: new Date().toISOString()
    };

    // Try to find main article content
    const articleSelectors = [
      'article',
      '[role="article"]',
      'main article',
      '.article-content',
      '.post-content',
      '.entry-content',
      '.content',
      'main',
      '#content',
      '.main-content'
    ];

    let articleElement = null;
    for (const selector of articleSelectors) {
      articleElement = document.querySelector(selector);
      if (articleElement) break;
    }

    // If no article element found, use body
    const sourceElement = articleElement || document.body;

    // Extract text content
    content.text = sourceElement.innerText || sourceElement.textContent || '';
    
    // Clean up text (remove excessive whitespace)
    content.text = content.text
      .replace(/\n\s*\n\s*\n/g, '\n\n') // Multiple newlines to double
      .replace(/[ \t]+/g, ' ') // Multiple spaces to single
      .trim();

    // Extract HTML (limited to first 50KB to avoid size issues)
    const htmlContent = sourceElement.innerHTML || '';
    content.html = htmlContent.substring(0, 50000);

    // Extract meta information
    const metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription) {
      content.description = metaDescription.content;
    }

    const metaAuthor = document.querySelector('meta[name="author"]');
    if (metaAuthor) {
      content.author = metaAuthor.content;
    }

    // Extract Open Graph data
    const ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) {
      content.ogTitle = ogTitle.content;
    }

    const ogDescription = document.querySelector('meta[property="og:description"]');
    if (ogDescription) {
      content.ogDescription = ogDescription.content;
    }

    return content;
  }

  /**
   * Listen for messages from popup/background
   */
  chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'extractContent') {
      try {
        const content = extractPageContent();
        sendResponse({ success: true, content });
      } catch (error) {
        sendResponse({ success: false, error: error.message });
      }
      return true; // Keep channel open for async response
    }
  });

  // Make extractPageContent available globally for debugging
  window.gtdExtractContent = extractPageContent;
})();
