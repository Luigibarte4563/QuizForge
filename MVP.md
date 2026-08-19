# QuizForge — UX-Focused MVP

## 1. What is QuizForge?

QuizForge turns your learning materials into a personal study session.

Upload a file or paste your notes, and QuizForge automatically creates:

- **Study Notes** — quickly review the important content
- **Flashcards** — memorize key concepts
- **Quizzes** — test your understanding
- **Progress** — see how much you've mastered

Everything works offline after the AI model is installed.

```
Simple user journey:

📄 Add Material
       ↓
🤖 QuizForge analyzes it
       ↓
📖 Review Notes
       ↓
🃏 Study Flashcards
       ↓
📝 Take Quiz
       ↓
📊 See Progress
       ↓
🏆 Master the Material
```

---

## 2. Main Navigation

Bottom navigation with 4 sections:

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│                   Current Screen                     │
│                                                      │
├──────────────────────────────────────────────────────┤
│   🏠 Home    📚 Materials    📊 Results    ⚙️ More   │
└──────────────────────────────────────────────────────┘
```

### 🏠 Home

The starting point.

- Add Material button
- Recent study materials
- Continue studying
- Current progress
- AI status indicator

### 📚 Materials

All uploaded learning materials.

```
My Materials

┌─────────────────────────────┐
│ 📄 Fundamentals of Database │
│ 72% Progress                │
│ ███████░░░ 72%              │
│                             │
│ Continue Studying →         │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 📄 Computer Hardware        │
│ 45% Progress                │
│ █████░░░░░ 45%              │
│                             │
│ Continue Studying →         │
└─────────────────────────────┘
```

### 📊 Results

Quiz history and performance.

```
Your Progress

Average Score
        86%

Quizzes Taken
        12

Materials Mastered
         3

Recent Results
────────────────────
Database          90%
Networking        85%
Hardware          78%
```

### ⚙️ More

Less frequently used features.

- Settings
- AI Model info
- Storage
- About QuizForge

---

## 3. Home Screen

The Home screen should immediately answer: **"What can I do?"**

```
Good morning, Luigi 👋

What would you like to study?


┌────────────────────────────────┐
│                                │
│       + Add Learning Material  │
│                                │
│   PDF • DOCX • PPTX • TXT      │
│                                │
└────────────────────────────────┘

[ Paste Text ]


─────────────────────────────────


Continue Studying


📘 Computer Hardware
72% mastered
[ Continue → ]


─────────────────────────────────


Quick Actions


[ 🃏 Flashcards ]  [ 📝 Quiz ]
```

Don't make users figure out what Mastery, Analysis, or Generation means before they can start.

---

## 4. Add Learning Material

Two obvious choices:

```
Add Learning Material

How do you want to add it?


┌───────────────────────────┐
│ 📄 Upload a File          │
│ PDF, DOCX, PPTX, TXT...   │
└───────────────────────────┘


┌───────────────────────────┐
│ ✏️ Paste Text             │
│ Paste your notes here     │
└───────────────────────────┘
```

---

## 5. Material Processing

Avoid technical messages like "Extracting XML from DOCX..."

The user doesn't care how the file is processed. Show:

```
Preparing your study material...


✓ Reading your file
✓ Understanding the content
● Creating study materials


This may take a moment.
```

When complete:

```
✨ Your material is ready!


Computer Hardware


We've created:
✓ Study Notes
✓ 20 Flashcards
✓ Quiz


[ Start Studying ]
```

---

## 6. Material Study Hub

This is the most important screen in the app — one central study dashboard per material.

```
← Computer Hardware


Computer Hardware
72% Mastered


██████████████░░░░░░ 72%


Keep studying to reach 100%.


────────────────────────


Your Study Tools


┌─────────────────────────────┐
│ 📖 Study Notes              │
│ Read and review the material│
│                         →   │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 🃏 Flashcards               │
│ Practice key concepts       │
│                         →   │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 📝 Take Quiz                │
│ Test your understanding     │
│                         →   │
└─────────────────────────────┘


────────────────────────


🏆 Progress
72% mastery


[ View Progress ]
```

---

## 7. Study Notes

Simply called **Study Notes**.

```
Computer Hardware


Study Notes


Computer hardware refers to the
physical components of a computer...


────────────────────────


Key Concepts


• CPU
• RAM
• Motherboard
• Storage
• Input devices
• Output devices


[ Edit Notes ]
```

---

## 8. Flashcards

Extremely simple interaction.

```
Flashcard 4 of 20


┌─────────────────────────────┐
│                             │
│ What is RAM?                │
│                             │
│        Tap to reveal        │
│                             │
└─────────────────────────────┘


                4 / 20


[ ← Previous ]     [ Next → ]
```

After tapping:

```
┌─────────────────────────────┐
│ What is RAM?                │
│                             │
│ RAM is temporary memory     │
│ used by a computer to store │
│ data currently being used.  │
└─────────────────────────────┘
```

---

## 9. Quiz Setup

Don't overwhelm with too many settings. **Mixed** is the default.

```
Start Quiz
Set Up Your Quiz


Number of Questions

[ 5 ] [ 10 ] [ 15 ] [ 20 ]


Difficulty

[ Easy ] [ Medium ] [ Hard ]


Question Type

[ Mixed ▼ ]


☑ Show explanations


        [ Start Quiz ]
```

---

## 10. Quiz Screen

The most important information visible immediately.

```
Question 4 of 10                    ⏱ 02:31


████████████░░░░░░ 40%


Which component stores temporary
data currently being used by the CPU?


○ A. HDD

○ B. RAM

○ C. GPU

○ D. PSU
```

After selecting:

```
✓ Correct!


RAM temporarily stores data currently
being used by the computer.


[ Next Question → ]
```

If explanations are disabled, move to the next question automatically.

---

## 11. Quiz Results

Result first, then statistics.

```
🎉 Quiz Complete!


        90%


Excellent work!


9 / 10 correct
Time: 04:32


██████████████████░░


────────────────────────


What to Review


❌ 1 Question to review


[ Review Mistakes ]


[ Study Again ]
```

Detailed statistics appear below.

---

## 12. Progress / Mastery

Instead of "Mastery", use **Progress** — students understand it faster.

```
Your Progress


Computer Hardware


        72%


██████████████░░░░░░


You've answered 36 of 50
questions correctly.


────────────────────────


Study Progress


📖 Notes          ✓ Completed
🃏 Flashcards     ✓ Completed
📝 Quizzes        72%
🏆 Challenge      🔒 Locked


Keep studying to unlock
the Challenge Quiz.
```

At 100%:

```
🎉 Material Mastered!


Computer Hardware


        100%


████████████████████


🏆 Challenge Unlocked!


Test yourself with the
Challenge Quiz.


[ Take Challenge ]
```

---

## 13. Challenge System

Make the unlock condition obvious.

Before unlocking:

```
🔒 Challenge Quiz


Reach 100% mastery to unlock
the Challenge Quiz.


Current Progress:


72%


██████████████░░░░░░


28% more to go.
```

After unlocking:

```
🏆 Challenge Unlocked!


You've mastered the material.


Can you get a perfect score?


[ Start Challenge ]
```

Stars:

```
Challenge Result


        ⭐⭐⭐


Excellent!


You earned 3 stars.
```

---

## 14. AI Status

Don't expose technical information to normal users.

In the app:

```
🤖 AI Ready
```

or:

```
🤖 AI Model
Ready
```

In Settings (for advanced users):

```
AI Model

Qwen3-1.7B

Running locally on your device.

Status
● Ready

Model Size
~1 GB

Internet Required
No
```

---

## 15. First Launch

The model is ~1 GB. Don't show a technical download screen immediately.

```
Welcome to QuizForge 👋


Your personal offline AI study
assistant.


Turn your learning materials into
notes, flashcards, and quizzes.


✓ Works offline
✓ Your files stay on your device
✓ AI runs directly on your phone


────────────────────


Before you start, QuizForge needs
to install its AI model.


Download size: ~1 GB


[ Download AI Model ]
```

Downloading:

```
Installing QuizForge AI...


██████████████░░░░ 72%


Downloading...
```

Complete:

```
🎉 You're Ready!


QuizForge AI is installed.


No internet connection is required
for studying.


[ Start Learning ]
```

---

## 16. Rename Technical Terms

Improve UX by renaming internal terms:

| Current | Better UX |
|---------|-----------|
| Material Analysis | Preparing Material |
| Mastery Detail | Study Material |
| Mastery Quiz | Quiz |
| Challenge Quiz | Challenge |
| Results | Quiz Results |
| Generate Quiz | Create Quiz |
| Source Text | Original Material |
| Mastery Percent | Progress |
| Mastery Tracker | Progress Tracker |
| Local AI Service | QuizForge AI |
| AI Pipeline | *(don't show to users)* |
| Offline Fallback | Automatic backup |
| Qwen3-1.7B | Advanced AI Model Info |

**The biggest one: Mastery → Progress.**

A student understands:

> "72% Progress"

much faster than:

> "Mastery: 72%"

You can still use "Mastered" when they reach 100%.

---

## 17. Recommended App Structure

```
                         QUIZFORGE
                             │
              ┌──────────────┴──────────────┐
              ↓                             ↓
          Add Material                 My Materials
          / Paste Text                       │
              │                             ↓
              └──────────────→ Study Material
                                      │
                    ┌─────────────────┼─────────────────┐
                    ↓                 ↓                 ↓
                📖 Notes          🃏 Flashcards     📝 Quiz
                                                        │
                                                        ↓
                                                    📊 Results
                                                        │
                                                        ↓
                                                    📈 Progress
                                                        │
                                                        ↓
                                                 🏆 Challenge
```

Bottom Navigation: **Home | Materials | Results | More**

No separate bottom-navigation items for Quizzes, Flashcards, Notes, Progress, Challenges — those belong to a specific learning material.

---

## 18. The UX Principle

The user should always know:

| Question | Example |
|----------|---------|
| **Where am I?** | Computer Hardware |
| **What should I do next?** | Study Flashcards |
| **How am I doing?** | 72% Progress |
| **What happens next?** | Reach 100% → Unlock Challenge |

QuizForge's mental model:

```
Add → Study → Quiz → Improve → Master
```

Much easier to understand than exposing the underlying AI, database, extraction, model, and generation architecture to the user.

---

## 19. Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart 3.12.2) |
| On-device LLM | nobodywho 2.5.0 (Qwen3-1.7B GGUF, Q4_K_M) |
| Database | sqflite (SQLite) |
| File Extraction | Pure Dart — archive 4.0.4 + xml 6.6.0 |
| File Picking | file_picker 10.0.0 |

---

## 20. Data Model

```
┌─────────────────────────────────────────────┐
│  materials (currently "mastery")             │
│  id, title, sourceText, notes, concepts,     │
│  progress, totalCorrect, totalAttempted,     │
│  challenge1/2Score, challenge1/2Unlocked,    │
│  mastered, stars, createdAt, updatedAt       │
├─────────────────────────────────────────────┤
│  quizzes                                     │
│  id, title, questions, settings,             │
│  sourceText, materialId (FK), createdAt      │
├─────────────────────────────────────────────┤
│  results                                     │
│  id, quizId (FK), quizTitle, score,          │
│  totalQuestions, topicResults,               │
│  completedAt, timeTakenSeconds               │
├─────────────────────────────────────────────┤
│  flashcards                                  │
│  id, materialId (FK), front, back, cardIndex │
└─────────────────────────────────────────────┘
```

---

## 21. Current State

### Implemented
- [x] File extraction (PDF, DOCX, PPTX, XLSX, TXT, RTF, HTML, JSON)
- [x] Paste text input
- [x] AI quiz generation (MCQ, T/F, FIB) with explanations
- [x] Offline quiz generation fallback
- [x] AI flashcard generation with offline fallback
- [x] Auto-generated study notes (full source text)
- [x] Editable notes in bottom sheet
- [x] Flashcard tap-to-reveal viewer
- [x] Quiz settings (count, type, difficulty)
- [x] Progress tracking with percentage
- [x] Challenge quizzes (unlock at 100%)
- [x] Star rating system
- [x] My Quizzes with study flow links
- [x] Delete cascade (material → quizzes → results → flashcards)
- [x] Explanation visibility fix (white background cards)
- [x] Save progress on quiz exit
- [x] Timer on all quiz screens
- [x] Model download screen with progress
- [x] AI status indicator on home screen

### TODO — UX Pass
- [ ] Rename "Mastery" → "Progress" / "Material" across all screens
- [ ] Rename "Review Notes" → "Study Notes"
- [ ] Rename "Material Analysis" → "Preparing Material"
- [ ] Simplify processing messages (no technical jargon)
- [ ] Welcome screen for first launch with friendly onboarding
- [ ] AI status: "🤖 AI Ready" instead of technical version string
- [ ] Settings: show model info in user-friendly format
- [ ] Quiz Setup: default to "Mixed" question type
- [ ] Quiz Results: result first, then stats
- [ ] Home: "Continue Studying" section with most recent material
- [ ] Home: Quick Actions (Flashcards, Quiz) shortcut
- [ ] Materials tab: show progress bar per material
- [ ] Bottom nav: consolidate to Home | Materials | Results | More
- [ ] Challenge unlock: show clear progress toward 100%

### Known Limitations
- nobodywho Gradle patch lost on `flutter pub get`
- No sync/backup (local only)
- No user accounts
- No image/media extraction from documents
- PDF extraction is text-based only (no OCR)
