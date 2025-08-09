import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["avatarBtn", "dropdown", "hamburgerBtn", "mobileMenu"];

  connect() {
    this._onDocClick = this._handleDocClick.bind(this);
    this._onKeyDown  = this._handleKeyDown.bind(this);
    document.addEventListener("click", this._onDocClick);
    document.addEventListener("keydown", this._onKeyDown);
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick);
    document.removeEventListener("keydown", this._onKeyDown);
  }

  toggleDropdown(event) {
    event.stopPropagation();
    if (this.hasDropdownTarget) this.dropdownTarget.classList.toggle("hidden");
  }

  toggleMobile(event) {
    event.stopPropagation();
    if (this.hasMobileMenuTarget) this.mobileMenuTarget.classList.toggle("hidden");
  }

  _handleDocClick(e) {
    if (this.hasDropdownTarget && !this.dropdownTarget.classList.contains("hidden")) {
      if (!this.dropdownTarget.contains(e.target) && e.target !== this.avatarBtnTarget) {
        this.dropdownTarget.classList.add("hidden");
      }
    }
    if (this.hasMobileMenuTarget && !this.mobileMenuTarget.classList.contains("hidden")) {
      if (!this.mobileMenuTarget.contains(e.target) && e.target !== this.hamburgerBtnTarget) {
        this.mobileMenuTarget.classList.add("hidden");
      }
    }
  }

  _handleKeyDown(e) {
    if (e.key === "Escape") {
      if (this.hasDropdownTarget)  this.dropdownTarget.classList.add("hidden");
      if (this.hasMobileMenuTarget) this.mobileMenuTarget.classList.add("hidden");
    }
  }
}
