# Signing — Hindukush

Release builds are signed in CI using material stored in **GitHub Actions
Secrets** — never committed to this repo. If a secret is absent, that platform
still builds, just unsigned.

Add these under **GitHub → Settings → Secrets and variables → Actions**:

| Secret name              | What it is                                             |
|--------------------------|--------------------------------------------------------|
| `ANDROID_KEYSTORE_BASE64`| base64 of the PKCS#12 keystore (`hindukush.p12`)       |
| `ANDROID_STORE_PASS`     | keystore store/key password                            |
| `WINDOWS_PFX_BASE64`     | base64 of the code-signing cert (`hindukush_windows.pfx`) |
| `WINDOWS_PFX_PASS`       | the .pfx password                                      |

The base64 blobs and passwords were delivered to the project owner separately
(not stored here). To create the base64 for a secret from a key file:

```bash
base64 -w0 hindukush.p12          # Linux
base64 -i hindukush.p12           # macOS
```

## Public fingerprints (safe to share)

**Android keystore** — alias `hindukush`, PKCS#12, RSA 2048, ~27 yr validity,
DN `CN=Hindukush Ghag, OU=Mobile, O=Hindukush, L=Kabul, ST=Kabul, C=AF`

- SHA-1: `FC:9C:79:C3:24:03:AD:3B:11:C1:5B:16:FE:45:06:E3:DA:27:4C:22`
- SHA-256: `9D:2C:6C:20:CD:20:85:1A:F1:86:F9:26:3D:5C:2C:5B:7F:70:EE:66:ED:02:E6:B1:A8:56:45:F3:EE:9F:20:67`

(These are what Google Play App Signing, Firebase, Maps, etc. key off — keep them.)

**Windows code-signing cert** — self-signed, RSA 2048, 10 yr, EKU Code Signing,
subject `CN=Hindukush Ghag, O=Hindukush, C=AF`

- SHA-1 thumbprint: `8B:4E:C5:0D:23:BC:F9:60:F5:CF:51:34:D5:80:3B:3B:FD:75:EA:62`

## Regenerating the keys

```bash
# Android
keytool -genkeypair -v -keystore hindukush.p12 -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias hindukush \
  -storepass '<PASSWORD>' -keypass '<PASSWORD>' \
  -dname "CN=Hindukush Ghag, OU=Mobile, O=Hindukush, L=Kabul, ST=Kabul, C=AF"

# Windows (self-signed code-signing .pfx)
openssl req -x509 -newkey rsa:2048 -keyout k.pem -out c.pem -days 3650 -nodes \
  -subj "/CN=Hindukush Ghag/O=Hindukush/C=AF" -addext "extendedKeyUsage=codeSigning"
openssl pkcs12 -export -out hindukush_windows.pfx -inkey k.pem -in c.pem -passout pass:'<PASSWORD>'
```

## Honest limitations

- **Windows:** a self-signed cert proves integrity but does **not** remove the
  SmartScreen / "Unknown publisher" prompt — only a paid OV/EV code-signing
  certificate from a public CA does. Swap the `.pfx`/secret for an OV cert and
  the workflow step is unchanged.
- **iOS:** CI produces an **unsigned** `.ipa` for sideloading (AltStore /
  Sideloadly). Store/ad-hoc signing needs a **paid Apple Developer account**
  (distribution cert + provisioning profile added as secrets).
