# APK Inspector (GitHub Actions)

Ye repo GitHub Actions se APK ka **static inspection** karega. APK ko run nahi karega.

## Use

1. Is folder ko GitHub repo mein upload karo.
2. Repo ko **Private** rakhna better hai agar APK tumhara/private hai.
3. APK ko `input/` folder mein `app.apk` naam se rakho.
4. Commit/push karo.
5. `Actions → Analyze APK` workflow complete hone do.
6. Workflow ke **Artifacts → apk-analysis** se result ZIP download karo.
7. Sabse pehle `network-indicators.txt` dekho.

## Kya nikalega

- AndroidManifest
- decoded resources
- DEX/JADX source (jab available ho)
- APK ke raw strings
- URLs/domains
- Firebase references
- Cloud Config references
- API/base URL/endpoint-like strings
- native `.so` aur `.dex` inventory
- SHA-256

## Important

Static analysis exact runtime endpoint ki guarantee nahi deta. Agar app protected/packed hai ya endpoint runtime par construct hota hai, to network capture ya runtime instrumentation alag step hoga.
