<script>
  import { createEventDispatcher } from 'svelte'
  import DailyReview from './DailyReview.svelte'

  const dispatch = createEventDispatcher()

  export let reviewType = null // null = show selector, 'morning' or 'evening' = show review

  // Auto-detect time of day if not specified
  const getDefaultType = () => {
    const hour = new Date().getHours()
    return hour < 12 ? 'morning' : 'evening'
  }

  const selectMorning = () => {
    reviewType = 'morning'
  }

  const selectEvening = () => {
    reviewType = 'evening'
  }

  const selectAuto = () => {
    reviewType = getDefaultType()
  }

  const handleReviewSaved = () => {
    dispatch('saved')
    dispatch('close')
  }

  const handleReviewClose = () => {
    reviewType = null
  }

  const handleBack = () => {
    if (reviewType) {
      reviewType = null
    } else {
      dispatch('close')
    }
  }
</script>

{#if reviewType}
  <DailyReview 
    reviewType={reviewType} 
    on:saved={handleReviewSaved}
    on:close={handleReviewClose}
  />
{:else}
  <div class="checkin-selector">
    <div class="header">
      <h2>🌅 Morning/Evening Check-In</h2>
      <button on:click={() => dispatch('close')} class="close-btn">×</button>
    </div>

    <div class="content">
      <p class="description">
        Choose your check-in type. The check-in process helps you start and end each day intentionally, 
        with structured reflection, planning, and habit tracking.
      </p>

      <div class="options">
        <button class="option-card morning" on:click={selectMorning}>
          <div class="option-icon">🌅</div>
          <div class="option-content">
            <h3>Morning Check-In</h3>
            <p>Set intentions, identify priorities, and plan your day</p>
          </div>
        </button>

        <button class="option-card evening" on:click={selectEvening}>
          <div class="option-icon">🌙</div>
          <div class="option-content">
            <h3>Evening Check-In</h3>
            <p>Reflect on accomplishments, review the day, and plan for tomorrow</p>
          </div>
        </button>

        <button class="option-card auto" on:click={selectAuto}>
          <div class="option-icon">⏰</div>
          <div class="option-content">
            <h3>Auto-Detect</h3>
            <p>Automatically choose based on current time ({getDefaultType() === 'morning' ? 'Morning' : 'Evening'})</p>
          </div>
        </button>
      </div>

      <div class="actions">
        <button on:click={() => dispatch('close')} class="btn-secondary">
          Cancel
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .checkin-selector {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    max-width: 800px;
    margin: 0 auto;
  }

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
  }

  .header h2 {
    font-size: 1.5rem;
    color: #333;
    margin: 0;
  }

  .close-btn {
    background: none;
    border: none;
    font-size: 2rem;
    cursor: pointer;
    color: #999;
    padding: 0;
    width: 2rem;
    height: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .close-btn:hover {
    color: #333;
  }

  .content {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .description {
    color: #666;
    font-size: 1rem;
    margin: 0;
    line-height: 1.6;
  }

  .options {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
  }

  .option-card {
    background: #f8f9fa;
    border: 2px solid #e9ecef;
    border-radius: 8px;
    padding: 1.5rem;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .option-card:hover {
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
  }

  .option-card.morning:hover {
    background: #fff9e6;
    border-color: #ffc107;
  }

  .option-card.evening:hover {
    background: #f0f4ff;
    border-color: #667eea;
  }

  .option-card.auto:hover {
    background: #f5f5f5;
    border-color: #999;
  }

  .option-icon {
    font-size: 3rem;
    text-align: center;
  }

  .option-content {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .option-content h3 {
    font-size: 1.2rem;
    color: #333;
    margin: 0;
  }

  .option-content p {
    font-size: 0.9rem;
    color: #666;
    margin: 0;
    line-height: 1.5;
  }

  .actions {
    display: flex;
    justify-content: flex-end;
    padding-top: 1rem;
    border-top: 2px solid #e9ecef;
  }

  .btn-secondary {
    padding: 0.75rem 2rem;
    background: #f8f9fa;
    color: #333;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-secondary:hover {
    background: #e9ecef;
    border-color: #ccc;
  }
</style>
