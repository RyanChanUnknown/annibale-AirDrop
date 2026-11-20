# Component notices

This project preserves upstream copyright and license notices. The root GPL-2.0 text applies to newly authored K90 integration code; it does not relicense third-party components or external inputs. Existing per-file SPDX expressions and licenses take precedence.

- K90 WLAN baseline: MiCode/vendor_qcom_opensource_wlan at the commit in `upstream-lock.json`, with the supplied K90 patch applied. Existing Qualcomm/Xiaomi/CodeAurora notices are retained.
- Houji bridge/Wonder/header support: ha0xin/houji-airdrop at the pinned commit. See `LICENSES/Houji-THIRD_PARTY_NOTICES.md`, GPL-2.0 and the individual file notices.
- Owly: MIT, copyright T4T5, with separate license notices for embedded components. The original license files remain in `upstream/houji/native/owly/`.
- Pandora session/compatibility reference: pinned AdenXie/pandora-airdrop; original GPL-2.0 text retained in `LICENSES/`.
- `firmware/get_amss20.py` and the maintainer recipe generator are adapted from Pandora commit `6e7b13bf7e6a866e9cee5f6575b56da023a2314a`, whose per-file SPDX and third-party notices identify these independently implemented tools as GPL-2.0-only. This does not extend that grant to other Houji-derived files. The S24 position recipe contains offsets and lengths, not firmware bytes.
- The Samsung EZIF firmware is an external proprietary input. No firmware image is distributed by this public repository or its release assets.
- The stock MiShare APK, patched boot images, signing private keys, ADB authorization keys, LSPosed databases and user files are not distributed here.

Runtime binaries retain their upstream licensing boundaries. The corresponding source and build references are supplied in the repository; kernel baselines/toolchains are pinned external inputs. No blanket relicensing is asserted for upstream files without a confirmed separate grant.
