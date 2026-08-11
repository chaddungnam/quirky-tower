# Gate A final-code visual evidence

Legacy before images are `not directly comparable` because they show the removed Timing Ring loop, not equivalent reboot states.

- HEAD: `c66e2e0b6221a7c82a33b9385966aab766ea6fe7`
- Branch: `codex/reboot-vertical-slice`
- Godot: `4.7-stable (official)`
- Renderer: `macOS Metal, mobile, Apple M2 (Apple8)`
- Platform: macOS desktop QA, offscreen window with an independent `SubViewport`
- Locale: `ko`
- Seed: `424242`
- Physical viewport: `1080x2400`
- Logical override: `720x1600`, stretch enabled; centered authored safe frame remains `720x1280`
- Source: `res://scenes/app/main.tscn` instantiated once
- Trigger: public Main/RunScreen paths and gameplay touch/drag/release through `SubViewport.push_input()`; transient world signals only pause settled or intentional intermediate captures
- Scope: macOS-rendered greybox structure and readability evidence; not Android/iOS, touch feel, performance, fun, or final art-fidelity proof

| State | Dimensions | SHA-256 |
| --- | --- | --- |
| `boot.png` | 1080x2400 | `63279d97c175b600e87cf430ec2ff8664c69c28ff51f1cc121abd132b533dd98` |
| `entry.png` | 1080x2400 | `342668170c86e5364624eb33473565f2fad5846f4a432d56a1ac7c723e76e880` |
| `brawl_warning.png` | 1080x2400 | `5cfbcf109305463751c537806e7eb245b5ab369af9baf011a6b7ef2f90c18f93` |
| `brawl_contact.png` | 1080x2400 | `2917c00932ac6c8c03929b028e677e3da45278227c79d4f0086491dc6ec10d02` |
| `brawl_rebound.png` | 1080x2400 | `873b4464fa0c8405052a6eab6bdb6adfeb4a7bda5dc0065d6402f51558217a3c` |
| `chain_path.png` | 1080x2400 | `b7cd95d5fbf1702c7d12b18e69cd252edc0cb72a2544710e76077a096009376e` |
| `chain_broken.png` | 1080x2400 | `02c4f01b88be1c86ade4a95e4a75cbe6cf15169718294f4136cbcf7d2ef3875f` |
| `chain_strike.png` | 1080x2400 | `4322a8437f3996bcfa08d869553dbac2da5467df2c321600fdc0381c552efa09` |
| `collapse_crack.png` | 1080x2400 | `8f4116ebab33afaab8a0a6b91dc8f67c3b8808d997be11e90621f5c9f771c24c` |
| `collapse_pieces.png` | 1080x2400 | `2b5a0bbd23e71bb946efae18af9b23fe459c44039930542b04c0d478e6c7b654` |
| `collapse_target.png` | 1080x2400 | `6b27b0f781bd5b51e9ce3dd84951dc6c8019161a398e50084351ad6340f0b632` |
| `collapse_reward.png` | 1080x2400 | `0506770e153de6e1ab97a38e8219e6046b7c05e4ba9775cf3e82d9540f7fca4d` |
| `choice.png` | 1080x2400 | `956fac1a8ce3693aaead17a70313ea614758d4eafb6a92d51d7e8e1cc5813f8f` |
| `result.png` | 1080x2400 | `35b921ab15563378b8e5b17d07130954c27b4c01f825897655e4e7cbf32abaa5` |
