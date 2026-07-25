---
name: Generate Demo Video
description: Analyzes the entire BabyHealth project, creates a demo presentation video using HyperFrames, renders it, and saves the MP4 to assets/video with sequential naming.
inclusion: manual
---

# Generate Demo Video Skill

You are tasked with creating a professional demo presentation video for the BabyHealth project. Follow these steps exactly:

## Step 1: Project Analysis

1. Read the `DESIGN.md` file at the project root to understand the full architecture, tech stack, and features.
2. Read the `README.md` for the project summary, live URL, and key characteristics.
3. Identify the key selling points:
   - AI-powered baby health orientation (not diagnosis)
   - Dual AI models: AWS Bedrock (Claude Sonnet) + Google Gemini
   - Video analysis with traffic-light results (green/yellow/red)
   - Cry classification (hunger, pain, sleep, etc.)
   - Bilingual (ES/EN), dark/light theme, responsive
   - Serverless architecture on AWS
   - Social login (Google, Facebook)
   - Privacy-first: videos deleted after 24h, profile data local-only

## Step 2: Compose the Demo Video with HyperFrames

Use the HyperFrames `compose` tool to create a demo presentation video. The prompt should instruct HyperFrames to create a compelling product demo covering:

1. **Opening hook** (3-5s): "BabyHealth — AI-Powered Baby Health Orientation"
2. **Problem statement** (5-7s): Parents worry about their baby's health, especially first-time parents
3. **Solution** (5-7s): Capture a short video → get instant AI analysis with actionable guidance
4. **Key features showcase** (10-15s):
   - Visual analysis (skin coloration, facial expressions, posture)
   - Cry classification (7 categories)
   - Traffic-light system (green/yellow/red)
   - Personalized context (baby profile data)
5. **Tech architecture highlight** (5-7s): Flutter + AWS serverless + dual AI (Bedrock + Gemini)
6. **Live demo URL** (3-5s): https://babyhealth.hmartinez.info
7. **Closing** (3-5s): Medical disclaimer + "Built at Hackathon Kiro 2026"

Use a warm, professional style with a healthcare/tech color palette. Target duration: 30-45 seconds.

## Step 3: Render the Video

Once the composition is created:

1. Call `render_video` on the project to generate the MP4.
2. Poll `get_render_status` until the render is complete.
3. Retrieve the download URL.

## Step 4: Save the Video with Sequential Naming

1. List existing files in `assets/video/` to determine the next serial number.
2. The naming pattern is: `BabyHealth-demo-NNN.mp4` where NNN is a zero-padded 3-digit serial (001, 002, 003...).
3. If no previous demos exist, start with `BabyHealth-demo-001.mp4`.
4. Download the rendered video from the URL and save it to `assets/video/BabyHealth-demo-NNN.mp4`.
5. If the download fails or the file is too large for direct save, create a markdown file `assets/video/BabyHealth-demo-NNN.md` with the download URL and metadata (render date, project ID, duration).

## Important Notes

- Always include the medical disclaimer: "Esta herramienta es solo orientativa. No reemplaza la evaluación médica profesional."
- The video should be bilingual or primarily in Spanish given the target audience.
- Use the project's live URL (https://babyhealth.hmartinez.info) as a reference.
- Keep the presentation concise and visually engaging.
- If HyperFrames MCP is not connected or authentication fails, inform the user and provide the manual steps to complete the task.
