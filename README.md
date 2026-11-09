# rd-sddm-themes

A collection of minimal, opinionated SDDM login themes.

---

## Themes

### nothing

> Dot-matrix widget login — inspired by Nothing OS.

A three-panel layout: dot-matrix clock · password login · system actions. Light grey background, dark widget cards, red accents.

![nothing theme screenshot](screenshots/nothing.png)

**Features**
- NDot55 dot-matrix font for the clock and labels
- Smooth fade-in entrance animation
- Click username pill to cycle users
- Click session button to cycle desktop sessions
- Shake animation on failed login

### ironclad

> Hot-rod editorial login — heavy Exo 2 type over a studio-grey backdrop.

![ironclad theme screenshot](screenshots/ironclad.png)

Left panel holds a headline-sized clock, username, underline password field and login button; the car stays clear on the right. Clickable session name at the bottom-left, system actions top-right, brake-caliper red accents.

**Features**
- Exo 2 (SIL OFL) Medium / Bold / ExtraBold, bundled in `themes/ironclad/font/`
- Click username to cycle users, click the session name (bottom-left) to cycle desktop sessions
- Shake animation on failed login

---

### pinkslip

> Street-sticker login — poster-weight type, hot-pink accents, and a licence-plate password field.

![pinkslip theme screenshot](screenshots/pinkslip.png)

A tall `HH:MM` clock in Anton with a blinking pink colon, a tilted black date tag, and the password field styled as a licence plate with a `GO` box. Machine name as a sticker top-left, outlined action pills top-right, and the session as a tag bottom-left. The car and its owner stay clear on the right.

**Features**
- Anton + Barlow Condensed (SIL OFL), bundled in `themes/pinkslip/font/`
- Click the pink username pill to cycle users, click the session tag to cycle desktop sessions
- Shake animation on failed login

---

## Installation

```bash
git clone https://github.com/senku/rd-sddm-themes
cd rd-sddm-themes
./install.sh
```

Run it as your normal user. The script lists the available themes and asks which one to install, then asks for your `sudo` password only when it needs to write to system folders. To skip the menu, pass the theme name: `./install.sh ironclad`.

It will:
1. Copy the chosen theme to `/usr/share/sddm/themes/`
2. Write `/etc/sddm.conf.d/theme.conf` with `Current=<theme>`

Then restart SDDM:

```bash
sudo systemctl restart sddm
```


---

## Requirements

- SDDM ≥ 0.20
- Qt 6
- Roboto or Inter system font (fallback to sans-serif)

---

## License

MIT
