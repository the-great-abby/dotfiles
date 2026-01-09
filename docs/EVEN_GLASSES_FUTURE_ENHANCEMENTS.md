# Even Glasses - Suggested Features & Enhancements

## 🔴 High Priority - Core Functionality

### 1. **Voice Capture Integration** (Mic Commands 0x0E, 0xF1)
**Impact**: High | **Complexity**: Medium

Enable quick capture via glasses microphone:
- Activate mic on glasses (Command 0x0E: enable=1)
- Receive audio data (Command 0xF1 with sequence numbers)
- Transcribe via speech-to-text (whisper.cpp, OpenAI, or local)
- Auto-capture to GTD inbox: `gtd-capture "transcribed text"`

**Use Case**: Hands-free task capture while walking, cooking, etc.

```bash
# Future command
gtd-glasses-capture
# → Activates mic, listens, transcribes, captures to inbox
```

**Integration Points**:
- `gtd-capture` command
- Daily log entries: `addInfoToDailyLog`
- Zettelkasten notes: `zet`

---

### 2. **Calendar Reminders on Glasses**
**Impact**: High | **Complexity**: Low

Send meeting reminders directly to glasses:
- Integrate with existing `gtd-calendar-reminder-worker`
- Display meeting info: title, time, location, attendees
- Auto-format for glasses display (compact, readable)

**Current State**: Calendar reminders exist but only send macOS notifications
**Enhancement**: Also send formatted reminders to glasses

**Format Example**:
```
Meeting: Team Standup
Starts in: 15 min
Location: Zoom Room A
```

---

### 3. **TouchBar Event Handling** (Command 0xF5)
**Impact**: Medium | **Complexity**: Medium

Handle user interactions on glasses:
- Single tap: Next action/navigation
- Double tap: Dismiss/close notification
- Triple tap: Toggle silent mode

**Use Cases**:
- Navigate through multi-screen notifications
- Dismiss notifications without phone
- Quick acknowledgment of tasks

**Integration**: 
- Pause automatic screen advancement on tap
- Allow manual navigation through pages
- Track dismissed notifications

---

### 4. **Notification Filtering & Priority**
**Impact**: Medium | **Complexity**: Low

Control what gets sent to glasses:
- Priority levels: urgent, normal, low
- Category filtering: calendar-only, tasks-only, all
- Time-based: Don't send during sleep hours
- Frequency limiting: Max X notifications per hour

**Configuration**:
```bash
# Only urgent notifications
EVEN_GLASSES_FILTER_PRIORITY="urgent"

# Calendar reminders only
EVEN_GLASSES_FILTER_CATEGORIES="calendar"

# Silent hours (don't send notifications)
EVEN_GLASSES_SILENT_HOURS="22:00-07:00"
```

---

## 🟡 Medium Priority - Enhanced Features

### 5. **Connection Pooling & Background Service**
**Impact**: Medium | **Complexity**: Medium

Keep connection alive for faster notifications:
- Background daemon maintains BLE connection
- Notification queue when glasses are disconnected
- Auto-reconnect on connection loss
- Connection status monitoring

**Benefits**:
- Instant notifications (no connection delay)
- Offline queue for when glasses are off
- Better battery management

**Implementation**: Launchd service or background worker

---

### 6. **Even AI Mode Integration** (Commands 0xF5 subcmd 23, 24)
**Impact**: Medium | **Complexity**: High

Integrate with glasses' native AI mode:
- Start Even AI (subcmd 23): Activate glasses AI
- Stop recording (subcmd 24): End AI session
- Use glasses' built-in AI for quick queries
- Sync results back to GTD system

**Use Case**: Ask glasses "What's my next task?" → Display on glasses

---

### 7. **Rich Text Formatting**
**Impact**: Medium | **Complexity**: Low

Better text presentation:
- **Bold/emphasis** markers (if supported)
- Bullet points and lists
- Compact formatting for dates/times
- Truncation with "..." indicators
- Smart wrapping (word boundaries, not character)

**Example Improvements**:
```
Current: "Task Complete Finish project proposal Great job!"

Better:
"✅ Task Complete
Finish project proposal
Great job!"
```

---

### 8. **BMP Image Support** (Commands 0x15, 0x20, 0x16)
**Impact**: Low | **Complexity**: High

Send images/icons to glasses:
- Status icons (✅, ❌, ⏰, etc.)
- Simple graphics/charts
- QR codes for quick actions
- Visual task lists

**Use Cases**:
- Visual task completion indicators
- Simple charts/dashboards
- QR codes to open actions on phone

---

### 9. **Wizard Menu Integration**
**Impact**: Medium | **Complexity**: Low

Add Even glasses setup to `gtd-wizard`:
- Test connection
- Configure device names
- Set notification preferences
- Enable/disable features
- Test notifications

**Menu Location**: `gtd-wizard → Configuration & Setup → Even Glasses`

---

### 10. **Daily Check-In on Glasses**
**Impact**: Medium | **Complexity**: Low

Send morning/evening summaries:
- Morning: Today's calendar, top tasks, weather
- Evening: Completed tasks, tomorrow's preview
- Triggered by `gtd-checkin` or scheduled

**Format**:
```
🌅 Morning Check-In
📅 3 meetings today
✓ Top 3 tasks
☀️ Sunny, 72°F
```

---

## 🟢 Low Priority - Nice to Have

### 11. **Notification History**
**Impact**: Low | **Complexity**: Low

Track what was sent to glasses:
- Log file: `~/.gtd/even_glasses/log.json`
- Query recent notifications
- Re-send missed notifications

---

### 12. **Battery Monitoring**
**Impact**: Low | **Complexity**: Medium

Monitor glasses battery level:
- Alert when battery low
- Auto-disable non-urgent notifications when low
- Display battery status in test script

---

### 13. **Multi-User Support**
**Impact**: Low | **Complexity**: Medium

Support multiple pairs of glasses:
- Switch between work/home glasses
- Different notification rules per pair
- Device selection in config

**Configuration**:
```bash
EVEN_GLASSES_PROFILES=(
  "work|Even-G1-L-Work|Even-G1-R-Work"
  "home|Even-G1-L-Home|Even-G1-R-Home"
)
```

---

### 14. **Notification Templates**
**Impact**: Low | **Complexity**: Low

Customizable notification formats:
- Task completion template
- Calendar reminder template
- Inbox notification template
- Custom emoji/icons per type

**Example**:
```bash
EVEN_GLASSES_TEMPLATE_TASK_COMPLETE="🎯 Done: {task}"
EVEN_GLASSES_TEMPLATE_CALENDAR="📅 {title} in {time}"
```

---

### 15. **Analytics & Metrics**
**Impact**: Low | **Complexity**: Low

Track glasses usage:
- Notifications sent per day
- Average response time (tap to dismiss)
- Most common notification types
- Connection uptime

---

## 🔧 Technical Improvements

### 16. **Better Error Handling**
**Impact**: High | **Complexity**: Low

- Retry logic for failed sends
- Clear error messages
- Graceful degradation (fallback to macOS notifications)
- Connection state tracking

---

### 17. **Protocol Compliance**
**Impact**: Medium | **Complexity**: Medium

Ensure full protocol compliance:
- Verify all command formats
- Handle all response codes (0xC9, 0xCA)
- Proper sequence number management
- CRC checks for BMP data (if implemented)

---

### 18. **Configuration Validation**
**Impact**: Medium | **Complexity**: Low

Validate config on startup:
- Check device names exist
- Verify BLE permissions
- Test connection
- Warn about misconfigurations

---

### 19. **Performance Optimization**
**Impact**: Medium | **Complexity**: Medium

- Batch notifications when possible
- Compress text before sending
- Reduce connection overhead
- Optimize packet size

---

### 20. **Testing & Debugging Tools**
**Impact**: Medium | **Complexity**: Low

Enhanced test utilities:
- `gtd-glasses-debug`: Detailed connection info
- `gtd-glasses-monitor`: Real-time status monitoring
- `gtd-glasses-simulate`: Test without actual glasses
- Protocol packet inspector

---

## 🎯 Recommended Implementation Order

### Phase 1: Foundation (Do First)
1. ✅ Connection & basic notifications (Done)
2. **Notification filtering** (#4)
3. **Calendar reminders** (#2)
4. **Better error handling** (#16)

### Phase 2: Enhanced Features
5. **TouchBar events** (#3)
6. **Connection pooling** (#5)
7. **Rich formatting** (#7)
8. **Wizard integration** (#9)

### Phase 3: Advanced Features
9. **Voice capture** (#1)
10. **Even AI mode** (#6)
11. **BMP images** (#8)
12. **Daily check-ins** (#10)

### Phase 4: Polish
13. Remaining features as needed

---

## 📋 Quick Wins (Easy & High Impact)

These can be implemented quickly with high value:

1. **Calendar reminders** - Already have calendar system, just route to glasses
2. **Notification filtering** - Simple config options
3. **Rich text formatting** - Just text formatting improvements
4. **Wizard integration** - Add menu items to existing wizard
5. **Daily check-ins** - Format existing summaries for glasses

---

## 🚀 Most Impactful Features

If I had to pick the top 3 most valuable features:

1. **Voice Capture** - Transform glasses into hands-free capture device
2. **Calendar Reminders** - Never miss meetings, see info at a glance
3. **TouchBar Navigation** - Interact with notifications directly on glasses

---

## 💡 Creative Ideas

### Glasses as Second Screen
- Display dashboard data (tasks, calendar, weather)
- Quick glance at system status
- Distraction-free information

### Context-Aware Notifications
- Location-based: Different notifications at home vs work
- Time-based: Meeting reminders in morning, task reminders in afternoon
- Activity-based: Pause during calendar events

### Quick Actions
- Swipe/tap to complete tasks
- Quick capture without phone
- Navigate GTD system via glasses

---

## 🤔 Questions to Consider

1. **How often will you wear the glasses?** → Affects priority of connection pooling
2. **Primary use case?** → Focus development accordingly
3. **Voice capture priority?** → High impact but requires speech-to-text setup
4. **Battery life concerns?** → Affects background service decisions
5. **Multi-device?** → Need multi-pair support

---

## 📝 Notes

- All suggestions based on EvenDemoApp protocol documentation
- Some features may require firmware updates or additional capabilities
- Prioritize based on your actual usage patterns
- Start with high-impact, low-complexity features
- Iterate based on real-world usage
