import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "ideabug-public-theme"

export default class extends Controller {
  static targets = ["toggle", "lightIcon", "darkIcon"]
  static values = {
    light: String,
    dark: String,
  }

  connect() {
    this.handleSystemThemeChange = this.systemThemeChanged.bind(this)
    this.applyResolvedTheme()

    if (this.mediaQuery.addEventListener) {
      this.mediaQuery.addEventListener("change", this.handleSystemThemeChange)
    } else {
      this.mediaQuery.addListener(this.handleSystemThemeChange)
    }
  }

  disconnect() {
    if (this.mediaQuery.removeEventListener) {
      this.mediaQuery.removeEventListener("change", this.handleSystemThemeChange)
    } else {
      this.mediaQuery.removeListener(this.handleSystemThemeChange)
    }
  }

  toggle() {
    const nextTheme = this.currentTheme === this.darkValue ? this.lightValue : this.darkValue
    this.storeTheme(nextTheme)
    this.applyTheme(nextTheme)
  }

  systemThemeChanged() {
    if (this.storedTheme) return
    this.applyResolvedTheme()
  }

  applyResolvedTheme() {
    this.applyTheme(this.resolvedTheme)
  }

  applyTheme(theme) {
    const darkActive = theme === this.darkValue

    document.documentElement.setAttribute("data-theme", theme)
    document.documentElement.style.colorScheme = darkActive ? "dark" : "light"

    this.toggleTargets.forEach((toggle) => {
      toggle.setAttribute("aria-pressed", String(darkActive))
      toggle.setAttribute("aria-label", darkActive ? "Switch to light mode" : "Switch to dark mode")
    })

    this.lightIconTargets.forEach((icon) => icon.classList.toggle("hidden", darkActive))
    this.darkIconTargets.forEach((icon) => icon.classList.toggle("hidden", !darkActive))
  }

  get currentTheme() {
    return document.documentElement.getAttribute("data-theme") || this.lightValue
  }

  get resolvedTheme() {
    return this.storedTheme || (this.mediaQuery.matches ? this.darkValue : this.lightValue)
  }

  get storedTheme() {
    try {
      return window.localStorage.getItem(STORAGE_KEY)
    } catch (_error) {
      return null
    }
  }

  storeTheme(theme) {
    try {
      window.localStorage.setItem(STORAGE_KEY, theme)
    } catch (_error) {
    }
  }

  get mediaQuery() {
    if (!this._mediaQuery) {
      this._mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    }

    return this._mediaQuery
  }
}
