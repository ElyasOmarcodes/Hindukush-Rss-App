"""Listening test: turn a few real Hindukush articles into speech with Gemini TTS.

Runs in GitHub Actions. Reads the API key from the GEMINI_KEY environment
variable (never printed). Writes MP3 files plus a notes file to ./tts_samples.
Stdlib only, plus the ffmpeg binary for PCM -> MP3.
"""
import base64
import html
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

SITE = os.environ.get("SITE", "https://hindukushpa.com")
COUNT = int(os.environ.get("COUNT", "2"))
VOICES = [v.strip() for v in os.environ.get("VOICES", "Kore,Charon").split(",") if v.strip()]
MAX_CHARS = int(os.environ.get("MAX_CHARS", "900"))
# Newest first; the first model that works is used for the whole run.
MODELS = [m.strip() for m in os.environ.get(
    "MODELS",
    "gemini-3.8-flash-lite-tts,gemini-3.8-flash-tts,gemini-2.5-flash-preview-tts",
).split(",") if m.strip()]

STYLE = (
    "Read the following Pashto news text aloud as a calm, clear Afghan Pashto "
    "news presenter would, with natural phrasing and correct Pashto "
    "pronunciation. Read only the text itself, nothing else:\n\n"
)

OUT = "tts_samples"
KEY = os.environ.get("GEMINI_KEY", "").strip()


def get_json(url, data=None, timeout=120):
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode() if data is not None else None,
        headers={"Content-Type": "application/json",
                 "User-Agent": "HindukushGhag-TTS-test/1.0"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def plain(h):
    h = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", h, flags=re.S | re.I)
    h = re.sub(r"</(p|div|h\d|li)>|<br\s*/?>", "\n", h, flags=re.I)
    h = re.sub(r"<[^>]+>", " ", h)
    h = html.unescape(h)
    h = re.sub(r"[ \t ]+", " ", h)
    return re.sub(r"\s*\n\s*", "\n", h).strip()


def clip(text, limit):
    """Cut at a sentence end before `limit` characters."""
    if len(text) <= limit:
        return text
    cut = text[:limit]
    ends = [cut.rfind(c) for c in ".۔؟!\n"]
    end = max(ends)
    return cut[: end + 1] if end > limit * 0.5 else cut


def synth(model, voice, text):
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/"
           f"{model}:generateContent?key={KEY}")
    body = {
        "contents": [{"parts": [{"text": STYLE + text}]}],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}
            },
        },
    }
    res = get_json(url, body, timeout=300)
    part = res["candidates"][0]["content"]["parts"][0]["inlineData"]
    return base64.b64decode(part["data"]), part.get("mimeType", "")


def to_mp3(pcm, path, mime):
    rate = re.search(r"rate=(\d+)", mime)
    rate = rate.group(1) if rate else "24000"
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", rate,
         "-ac", "1", "-i", "pipe:0", "-b:a", "64k", path],
        input=pcm, check=True,
    )


def error_text(e):
    if isinstance(e, urllib.error.HTTPError):
        try:
            msg = json.loads(e.read().decode())["error"]["message"]
        except Exception:
            msg = str(e)
        return f"HTTP {e.code}: {msg}".replace(KEY, "***") if KEY else msg
    return str(e).replace(KEY, "***") if KEY else str(e)


def main():
    if not KEY:
        print("GEMINI_KEY is empty: add it under Settings > Secrets (or Variables).")
        return 1
    os.makedirs(OUT, exist_ok=True)
    notes = []

    posts = get_json(f"{SITE}/wp-json/wp/v2/posts?per_page={COUNT}"
                     "&_fields=id,link,title,content")
    model_ok = None
    for i, p in enumerate(posts, 1):
        title = plain(p["title"]["rendered"])
        body = clip(plain(p["content"]["rendered"]), MAX_CHARS)
        text = f"{title}.\n\n{body}"
        notes.append(f"=== Article {i} === {p['link']}\n{text}\n")
        for voice in VOICES:
            for model in ([model_ok] if model_ok else MODELS):
                try:
                    pcm, mime = synth(model, voice, text)
                    name = f"{OUT}/article{i}_{voice}.mp3"
                    to_mp3(pcm, name, mime)
                    model_ok = model
                    notes.append(f"OK  {name}  (model {model})")
                    print(f"OK article {i} voice {voice} model {model}")
                    break
                except Exception as e:  # try the next model
                    msg = error_text(e)
                    notes.append(f"ERR article {i} voice {voice} model {model}: {msg}")
                    print(f"ERR article {i} voice {voice} model {model}: {msg}")

    with open(f"{OUT}/README.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(notes))
    made = [n for n in os.listdir(OUT) if n.endswith(".mp3")]
    print(f"{len(made)} audio files")
    return 0 if made else 1


if __name__ == "__main__":
    sys.exit(main())
