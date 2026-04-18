(function () {
  if (window.IdeabugWidget) return;

  const STORAGE_KEY = "ideabug:state";
  const ANON_HEADER = "X-Ideabug-Anon-Id";
  const POLL_VISIBLE_MS_DEFAULT = 60000;
  const POLL_HIDDEN_MS_DEFAULT = 300000;
  const POLL_MIN_MS = 5000;
  const VOTE_DEBOUNCE_MS = 600;

  function loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return { v: 1 };
      const parsed = JSON.parse(raw);
      return parsed && parsed.v === 1 ? parsed : { v: 1 };
    } catch (_) {
      return { v: 1 };
    }
  }

  function saveState(state) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (_) {}
  }

  function escapeHtml(value) {
    if (value == null) return "";
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function timeAgo(iso) {
    if (!iso) return "";
    const diff = (Date.now() - new Date(iso).getTime()) / 1000;
    if (diff < 60) return "just now";
    if (diff < 3600) return Math.floor(diff / 60) + "m ago";
    if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
    if (diff < 604800) return Math.floor(diff / 86400) + "d ago";
    return new Date(iso).toLocaleDateString();
  }

  function bucketByWeek(items) {
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);
    const startOfLastWeek = new Date(startOfWeek);
    startOfLastWeek.setDate(startOfWeek.getDate() - 7);

    const buckets = { "This week": [], "Last week": [], Earlier: [] };
    items.forEach((item) => {
      const t = new Date(item.published_at || item.created_at).getTime();
      if (t >= startOfWeek.getTime()) buckets["This week"].push(item);
      else if (t >= startOfLastWeek.getTime()) buckets["Last week"].push(item);
      else buckets["Earlier"].push(item);
    });
    return buckets;
  }

  function bellSvg() {
    return (
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      '<path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"></path>' +
      '<path d="M13.73 21a2 2 0 0 1-3.46 0"></path>' +
      "</svg>"
    );
  }

  function heartSvg(filled) {
    const fill = filled ? "currentColor" : "none";
    return (
      '<svg viewBox="0 0 24 24" fill="' +
      fill +
      '" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      '<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>' +
      "</svg>"
    );
  }

  class IdeabugClient {
    constructor(host) {
      this.host = host.replace(/\/$/, "");
    }

    async headers(extra) {
      const h = Object.assign({ "Content-Type": "application/json" }, extra || {});
      const state = loadState();
      if (state.anonymous_id) h[ANON_HEADER] = state.anonymous_id;
      if (typeof this._jwtFn === "function") {
        try {
          const jwt = await this._jwtFn();
          if (jwt) h["Authorization"] = "Bearer " + jwt;
        } catch (_) {}
      }
      return h;
    }

    setJwtFn(fn) {
      this._jwtFn = fn;
    }

    async request(method, path, body) {
      const opts = { method: method, headers: await this.headers(), credentials: "omit" };
      if (body !== undefined) opts.body = JSON.stringify(body);
      const res = await fetch(this.host + path, opts);
      const data = res.status === 204 ? null : await res.json().catch(() => null);
      return { ok: res.ok, status: res.status, data: data, headers: res.headers };
    }

    identify() { return this.request("POST", "/api/v1/identity"); }
    listAnnouncements() { return this.request("GET", "/api/v1/announcements"); }
    markRead(id) { return this.request("POST", "/api/v1/announcements/" + id + "/read"); }
    markAllRead() { return this.request("POST", "/api/v1/announcements/read_all"); }
    optOut() { return this.request("POST", "/api/v1/announcements/opt_out"); }
    optIn() { return this.request("POST", "/api/v1/announcements/opt_in"); }
    listFeatures(sort) { return this.request("GET", "/api/v1/tickets?type=feature&sort=" + (sort || "top")); }
    listMine() { return this.request("GET", "/api/v1/tickets?mine=1"); }
    submit(payload) { return this.request("POST", "/api/v1/tickets", { ticket: payload }); }
    vote(id) { return this.request("POST", "/api/v1/tickets/" + id + "/vote"); }
    unvote(id) { return this.request("DELETE", "/api/v1/tickets/" + id + "/vote"); }
    roadmap() { return this.request("GET", "/api/v1/roadmap"); }
  }

  class IdeabugWidget {
    constructor() {
      this.config = null;
      this.client = null;
      this.target = null;
      this.root = null;
      this.panel = null;
      this.bell = null;
      this.state = loadState();
      this.tab = this.state.last_tab || "updates";
      this.announcements = [];
      this.unread = 0;
      this.optedOut = false;
      this.roadmapData = null;
      this.featuresData = null;
      this._pollTimer = null;
      this._voteLock = {};
    }

    configure(config) {
      this.config = Object.assign({}, this.config || {}, config || {});

      // The jwt callable can arrive before or after apiHost — apply it whenever
      // both the client exists and the callable is set.
      if (this.client && typeof this.config.jwt === "function") {
        this.client.setJwtFn(this.config.jwt);
      }

      this._maybeStart();
    }

    _maybeStart() {
      if (this._started) return;
      if (!this.config.apiHost || !this.config.targetElement) return;

      const target =
        typeof this.config.targetElement === "string"
          ? document.querySelector(this.config.targetElement)
          : this.config.targetElement;
      if (!target) {
        console.warn("[ideabug] target not found", this.config.targetElement);
        return;
      }

      this.target = target;
      this.client = new IdeabugClient(this.config.apiHost);
      if (typeof this.config.jwt === "function") {
        this.client.setJwtFn(this.config.jwt);
      }
      this._started = true;
      this.start();
    }

    async start() {
      this.renderShell();
      try {
        const id = await this.client.identify();
        if (id.ok && id.data) {
          this.state.anonymous_id = id.data.anonymous_id || this.state.anonymous_id;
          this.optedOut = !!id.data.opted_out;
          saveState(this.state);
        }
      } catch (e) {
        console.warn("[ideabug] identity failed", e);
      }
      await this.refreshAnnouncements();
      this.startPolling();
    }

    startPolling() {
      const tick = () => this.refreshAnnouncements();
      const schedule = () => {
        clearTimeout(this._pollTimer);
        const visibleMs = Math.max(POLL_MIN_MS, this.config.pollInterval || POLL_VISIBLE_MS_DEFAULT);
        const hiddenMs = Math.max(visibleMs, this.config.pollIntervalHidden || POLL_HIDDEN_MS_DEFAULT);
        const ms = document.visibilityState === "hidden" ? hiddenMs : visibleMs;
        this._pollTimer = setTimeout(async () => {
          await tick();
          schedule();
        }, ms);
      };
      document.addEventListener("visibilitychange", schedule);
      schedule();
    }

    async refreshAnnouncements() {
      const res = await this.client.listAnnouncements();
      if (!res.ok) return;
      this.announcements = res.data || [];
      const u = parseInt(res.headers.get("X-Ideabug-Unread") || "0", 10);
      this.unread = isNaN(u) ? 0 : u;
      const optHeader = res.headers.get("X-Ideabug-Opted-Out");
      if (optHeader != null) this.optedOut = optHeader === "true";
      this.renderBell();
      if (this.tab === "updates") this.renderUpdates();
    }

    renderShell() {
      this.root = document.createElement("div");
      this.root.className = "ideabug-root";
      this.root.dataset.testid = "ideabug-root";

      this.bell = document.createElement("button");
      this.bell.type = "button";
      this.bell.className = "ideabug-bell";
      this.bell.setAttribute("aria-label", "Open updates");
      this.bell.innerHTML = bellSvg() + '<span class="ideabug-bell-badge is-hidden"></span>';
      this.bell.addEventListener("click", (e) => {
        e.stopPropagation();
        this.togglePanel();
      });
      this.target.appendChild(this.bell);

      this.panel = document.createElement("div");
      this.panel.className = "ideabug-panel";
      this.panel.dataset.testid = "ideabug-panel";
      this.panel.innerHTML =
        '<div class="ideabug-tabs" role="tablist">' +
        '<button class="ideabug-tab" role="tab" data-tab="updates">Updates</button>' +
        '<button class="ideabug-tab" role="tab" data-tab="suggest">Suggest</button>' +
        '<button class="ideabug-tab" role="tab" data-tab="roadmap">Roadmap</button>' +
        "</div>" +
        '<div class="ideabug-body" data-testid="ideabug-body"></div>';
      this.root.appendChild(this.panel);

      this.panel.querySelectorAll(".ideabug-tab").forEach((tab) => {
        tab.addEventListener("click", () => this.activateTab(tab.dataset.tab));
      });

      this.modalOverlay = document.createElement("div");
      this.modalOverlay.className = "ideabug-modal-overlay";
      this.modalOverlay.setAttribute("role", "dialog");
      this.modalOverlay.setAttribute("aria-modal", "true");
      this.modalOverlay.dataset.testid = "ideabug-modal-overlay";
      this.modalOverlay.innerHTML =
        '<div class="ideabug-modal" data-testid="ideabug-modal">' +
        '<button type="button" class="ideabug-modal-nav ideabug-modal-nav-prev" data-action="modal-prev" aria-label="Previous announcement">&larr;</button>' +
        '<button type="button" class="ideabug-modal-nav ideabug-modal-nav-next" data-action="modal-next" aria-label="Next announcement">&rarr;</button>' +
        '<header class="ideabug-modal-header">' +
        '<div class="ideabug-modal-title-block">' +
        '<h2 class="ideabug-modal-title" data-testid="modal-title"></h2>' +
        '<div class="ideabug-modal-meta" data-testid="modal-meta"></div>' +
        "</div>" +
        '<button type="button" class="ideabug-modal-close" data-action="modal-close" aria-label="Close">&times;</button>' +
        "</header>" +
        '<div class="ideabug-modal-body" data-testid="modal-body"></div>' +
        '<footer class="ideabug-modal-footer">' +
        '<span class="ideabug-modal-meta" data-testid="modal-position"></span>' +
        '<span class="ideabug-modal-meta">Use ← → to navigate · Esc to close</span>' +
        "</footer>" +
        "</div>";
      this.root.appendChild(this.modalOverlay);

      this.modalOverlay.addEventListener("click", (e) => {
        if (e.target === this.modalOverlay) this.closeModal();
      });
      this.modalOverlay.querySelector('[data-action="modal-close"]')
        .addEventListener("click", () => this.closeModal());
      this.modalOverlay.querySelector('[data-action="modal-prev"]')
        .addEventListener("click", () => this.navigateModal(-1));
      this.modalOverlay.querySelector('[data-action="modal-next"]')
        .addEventListener("click", () => this.navigateModal(1));

      document.body.appendChild(this.root);

      // Stop clicks inside our chrome from reaching the document-level
      // outside-click handler. Without this, any click handler that
      // re-renders innerHTML detaches the click target from the DOM, making
      // root.contains(e.target) return false → panel mistakenly closes.
      this.root.addEventListener("click", (e) => e.stopPropagation());

      document.addEventListener("click", (e) => {
        if (this.modalOverlay.classList.contains("is-open")) return;
        if (!this.root.contains(e.target)) this.closePanel();
      });
      document.addEventListener("keydown", (e) => this.onKeydown(e));
      this.renderBell();
    }

    onKeydown(e) {
      if (!this.modalOverlay.classList.contains("is-open")) return;
      if (e.key === "Escape") { e.preventDefault(); this.closeModal(); return; }
      if (e.key === "ArrowLeft") { e.preventDefault(); this.navigateModal(-1); return; }
      if (e.key === "ArrowRight") { e.preventDefault(); this.navigateModal(1); return; }
    }

    togglePanel() {
      if (this.panel.classList.contains("is-open")) this.closePanel();
      else this.openPanel();
    }

    openPanel() {
      this.positionPanel();
      this.panel.classList.add("is-open");
      this.activateTab(this.tab || "updates");
    }

    closePanel() {
      this.panel.classList.remove("is-open");
    }

    positionPanel() {
      const rect = this.target.getBoundingClientRect();
      const gap = 8;
      const top = Math.min(window.innerHeight - 528, rect.bottom + gap);
      const left = Math.max(12, Math.min(window.innerWidth - 372, rect.left));
      this.panel.style.top = top + "px";
      this.panel.style.left = left + "px";
    }

    activateTab(name) {
      this.tab = name;
      this.state.last_tab = name;
      saveState(this.state);
      this.panel.querySelectorAll(".ideabug-tab").forEach((t) => {
        t.classList.toggle("is-active", t.dataset.tab === name);
      });
      if (name === "updates") this.renderUpdates();
      else if (name === "suggest") this.renderSuggest();
      else if (name === "roadmap") this.renderRoadmap();
    }

    renderBell() {
      const badge = this.bell.querySelector(".ideabug-bell-badge");
      if (this.optedOut || this.unread <= 0) {
        badge.className = "ideabug-bell-badge is-hidden";
        badge.textContent = "";
        return;
      }
      if (this.unread <= 3) {
        badge.className = "ideabug-bell-badge";
        badge.textContent = "";
      } else {
        badge.className = "ideabug-bell-badge is-count";
        badge.textContent = this.unread > 99 ? "99+" : String(this.unread);
      }
    }

    body() {
      return this.panel.querySelector('[data-testid="ideabug-body"]');
    }

    renderUpdates() {
      const body = this.body();
      const items = this.announcements;
      const banner = this.optedOut
        ? '<div class="ideabug-banner">Updates are muted. <button type="button" class="ideabug-link" data-action="opt-in">Re-enable</button></div>'
        : "";

      if (!items.length) {
        body.innerHTML =
          banner +
          '<div class="ideabug-empty">No updates yet. We\'ll show new announcements here.</div>';
        return;
      }

      const buckets = bucketByWeek(items);
      let html = banner;
      ["This week", "Last week", "Earlier"].forEach((label) => {
        const list = buckets[label];
        if (!list.length) return;
        html += '<div class="ideabug-section-title">' + label + "</div>";
        list.forEach((a) => {
          html +=
            '<div class="ideabug-item ' +
            (a.read ? "" : "is-unread") +
            '" data-id="' +
            a.id +
            '" data-action="open-announcement">' +
            '<div class="ideabug-item-title">' +
            escapeHtml(a.title) +
            "</div>" +
            '<div class="ideabug-item-meta">' +
            timeAgo(a.published_at || a.created_at) +
            "</div>" +
            (a.preview ? '<div class="ideabug-item-preview">' + escapeHtml(a.preview) + "</div>" : "") +
            "</div>";
        });
      });
      html +=
        '<div class="ideabug-footer">' +
        '<button type="button" class="ideabug-link" data-action="mark-all">Mark all as read</button>' +
        '<button type="button" class="ideabug-link" data-action="opt-out">Mute updates</button>' +
        "</div>";
      body.innerHTML = html;

      body.querySelectorAll('[data-action="open-announcement"]').forEach((el) => {
        el.addEventListener("click", () => this.openAnnouncement(parseInt(el.dataset.id, 10)));
      });
      const markAll = body.querySelector('[data-action="mark-all"]');
      if (markAll) markAll.addEventListener("click", () => this.markAllRead());
      const optOut = body.querySelector('[data-action="opt-out"]');
      if (optOut) optOut.addEventListener("click", () => this.toggleOptOut(true));
      const optIn = body.querySelector('[data-action="opt-in"]');
      if (optIn) optIn.addEventListener("click", () => this.toggleOptOut(false));
    }

    openAnnouncement(id) {
      const idx = this.announcements.findIndex((a) => a.id === id);
      if (idx < 0) return;
      this._modalIndex = idx;
      this.modalOverlay.classList.add("is-open");
      this.renderModal();
    }

    closeModal() {
      this.modalOverlay.classList.remove("is-open");
      this._modalIndex = null;
    }

    navigateModal(delta) {
      if (this._modalIndex == null) return;
      const next = this._modalIndex + delta;
      if (next < 0 || next >= this.announcements.length) return;
      this._modalIndex = next;
      this.renderModal();
    }

    async renderModal() {
      const item = this.announcements[this._modalIndex];
      if (!item) return;

      const titleEl    = this.modalOverlay.querySelector('[data-testid="modal-title"]');
      const metaEl     = this.modalOverlay.querySelector('[data-testid="modal-meta"]');
      const bodyEl     = this.modalOverlay.querySelector('[data-testid="modal-body"]');
      const positionEl = this.modalOverlay.querySelector('[data-testid="modal-position"]');
      const prevBtn    = this.modalOverlay.querySelector('[data-action="modal-prev"]');
      const nextBtn    = this.modalOverlay.querySelector('[data-action="modal-next"]');

      titleEl.textContent = item.title || "";
      metaEl.textContent = timeAgo(item.published_at || item.created_at);
      bodyEl.innerHTML = item.content || '<p style="color:var(--ib-muted)">No content.</p>';
      bodyEl.scrollTop = 0;
      positionEl.textContent = (this._modalIndex + 1) + " of " + this.announcements.length;

      prevBtn.disabled = this._modalIndex === 0;
      nextBtn.disabled = this._modalIndex >= this.announcements.length - 1;

      // Mark as read on open + re-render the list row state in the panel.
      if (!item.read) {
        const res = await this.client.markRead(item.id);
        if (res.ok && res.data) {
          item.read = true;
          this.unread = Math.max(0, this.unread - 1);
          this.renderBell();
          if (this.tab === "updates") this.refreshItemReadState(item.id);
        }
      }
    }

    refreshItemReadState(id) {
      const row = this.body().querySelector('[data-action="open-announcement"][data-id="' + id + '"]');
      if (row) row.classList.remove("is-unread");
    }

    async markAllRead() {
      const res = await this.client.markAllRead();
      if (!res.ok) return;
      this.announcements.forEach((a) => (a.read = true));
      this.unread = 0;
      this.renderBell();
      this.renderUpdates();
    }

    async toggleOptOut(out) {
      const res = out ? await this.client.optOut() : await this.client.optIn();
      if (!res.ok) return;
      this.optedOut = out;
      if (out) this.unread = 0;
      this.renderBell();
      this.renderUpdates();
    }

    renderSuggest() {
      const subTab = this._suggestSubTab || "new";
      const body = this.body();
      body.innerHTML =
        '<div class="ideabug-suggest-tabs">' +
        '<button type="button" class="ideabug-suggest-tab ' + (subTab === "new" ? "is-active" : "") + '" data-suggest-sub="new">New</button>' +
        '<button type="button" class="ideabug-suggest-tab ' + (subTab === "mine" ? "is-active" : "") + '" data-suggest-sub="mine">My submissions</button>' +
        "</div>" +
        '<div data-testid="ideabug-suggest-body"></div>';

      body.querySelectorAll("[data-suggest-sub]").forEach((btn) => {
        btn.addEventListener("click", () => {
          this._suggestSubTab = btn.dataset.suggestSub;
          this.renderSuggest();
        });
      });

      if (subTab === "new") this.renderSuggestForm();
      else this.renderMySubmissions();
    }

    suggestBody() {
      return this.body().querySelector('[data-testid="ideabug-suggest-body"]');
    }

    renderSuggestForm() {
      const body = this.suggestBody();
      body.innerHTML =
        '<form class="ideabug-form" data-action="suggest-form">' +
        '<div class="ideabug-segmented" role="tablist">' +
        '<button type="button" data-kind="feature_request" class="is-active">Feature request</button>' +
        '<button type="button" data-kind="bug">Bug</button>' +
        "</div>" +
        '<input class="ideabug-input" name="title" placeholder="Title" required maxlength="120" />' +
        '<textarea class="ideabug-textarea" name="description" placeholder="Describe what you have in mind…" maxlength="2000"></textarea>' +
        '<button type="submit" class="ideabug-btn">Send</button>' +
        "</form>";

      let kind = "feature_request";
      body.querySelectorAll(".ideabug-segmented button").forEach((btn) => {
        btn.addEventListener("click", () => {
          kind = btn.dataset.kind;
          body.querySelectorAll(".ideabug-segmented button").forEach((b) => {
            b.classList.toggle("is-active", b === btn);
          });
        });
      });

      body.querySelector("form").addEventListener("submit", async (e) => {
        e.preventDefault();
        const form = e.target;
        const button = form.querySelector("button[type=submit]");
        button.disabled = true;
        const payload = {
          title: form.title.value.trim(),
          description: form.description.value.trim(),
          classification: kind
        };
        if (kind === "bug") {
          payload.context = {
            url: location.href,
            user_agent: navigator.userAgent,
            viewport: window.innerWidth + "x" + window.innerHeight
          };
        }
        const res = await this.client.submit(payload);
        if (!res.ok) {
          button.disabled = false;
          body.insertAdjacentHTML(
            "afterbegin",
            '<div class="ideabug-banner">Could not submit. Please try again.</div>'
          );
          return;
        }
        body.innerHTML =
          '<div class="ideabug-success">' +
          (kind === "feature_request"
            ? '<p>Thanks! Your idea is on the public roadmap.</p>' +
              '<button type="button" class="ideabug-link" data-action="goto-mine">View your submissions</button>'
            : '<p>Thanks for reporting. We will look into it.</p>' +
              '<button type="button" class="ideabug-link" data-action="goto-mine">View your submissions</button>') +
          "</div>";
        const goto = body.querySelector('[data-action="goto-mine"]');
        if (goto) {
          goto.addEventListener("click", () => {
            this._suggestSubTab = "mine";
            this.renderSuggest();
          });
        }
      });
    }

    async renderMySubmissions() {
      const body = this.suggestBody();
      body.innerHTML = '<div class="ideabug-empty">Loading…</div>';
      const res = await this.client.listMine();
      if (!res.ok) {
        body.innerHTML = '<div class="ideabug-empty">Could not load your submissions.</div>';
        return;
      }
      const items = res.data || [];
      if (!items.length) {
        body.innerHTML =
          '<div class="ideabug-empty">' +
          'You have not submitted anything yet.' +
          '<div style="margin-top:8px"><button type="button" class="ideabug-link" data-action="goto-new">Submit something</button></div>' +
          "</div>";
        const goto = body.querySelector('[data-action="goto-new"]');
        if (goto) goto.addEventListener("click", () => { this._suggestSubTab = "new"; this.renderSuggest(); });
        return;
      }

      let html = "";
      items.forEach((t) => {
        const status = (t.status || "").replace("_", " ");
        const cls = (t.classification || "").replace("_", " ");
        const statusClass = "ideabug-status-" + (t.status || "new");
        html +=
          '<div class="ideabug-item">' +
          '<div class="ideabug-item-title">' + escapeHtml(t.title || "(no title)") + "</div>" +
          '<div class="ideabug-item-meta">' +
          '<span class="ideabug-chip">' + escapeHtml(cls) + "</span>" +
          '<span class="ideabug-chip ' + statusClass + '">' + escapeHtml(status) + "</span>" +
          '<span style="margin-left:6px">' + timeAgo(t.created_at) + "</span>" +
          (t.classification === "feature_request" && t.public_on_roadmap
            ? '<span style="margin-left:6px">' + (t.votes_count || 0) + " votes</span>"
            : "") +
          "</div>" +
          (t.description ? '<div class="ideabug-item-preview">' + escapeHtml(t.description.slice(0, 140)) + (t.description.length > 140 ? "…" : "") + "</div>" : "") +
          "</div>";
      });
      body.innerHTML = html;
    }

    async renderRoadmap() {
      const body = this.body();
      body.innerHTML = '<div class="ideabug-empty">Loading…</div>';
      const res = await this.client.roadmap();
      if (!res.ok) {
        body.innerHTML = '<div class="ideabug-empty">Roadmap unavailable.</div>';
        return;
      }
      this.roadmapData = res.data;
      const featuresRes = await this.client.listFeatures("top");
      this.featuresData = featuresRes.ok ? featuresRes.data || [] : [];
      const votedSet = new Set(this.featuresData.filter((f) => f.voted_by_me).map((f) => f.id));

      const renderSection = (label, items, opts) => {
        if (!items || !items.length) return "";
        let html = '<div class="ideabug-section-title">' + label + "</div>";
        items.forEach((t) => {
          const isFeature = t.classification === "feature_request";
          const dateLabel = opts.dateField && t[opts.dateField]
            ? new Date(t[opts.dateField]).toLocaleDateString()
            : "";
          const voted = votedSet.has(t.id);
          const voteBtn = isFeature && opts.allowVote
            ? '<button type="button" class="ideabug-vote ' +
              (voted ? "is-voted" : "") +
              '" data-action="toggle-vote" data-id="' +
              t.id +
              '">' +
              heartSvg(voted) +
              "<span>" +
              (t.votes_count || 0) +
              "</span></button>"
            : "";
          html +=
            '<div class="ideabug-roadmap-card" data-id="' +
            t.id +
            '"><div><div class="ideabug-item-title">' +
            escapeHtml(t.title) +
            '</div><div class="ideabug-roadmap-card-meta">' +
            (dateLabel ? '<span class="ideabug-chip">' + dateLabel + "</span>" : "") +
            '<span class="ideabug-chip">' +
            t.classification.replace("_", " ") +
            "</span></div></div>" +
            voteBtn +
            "</div>";
        });
        return html;
      };

      // Ideas should only show items NOT already represented in now/next/shipped.
      const placedIds = new Set([
        ...(this.roadmapData.now || []).map((t) => t.id),
        ...(this.roadmapData.next || []).map((t) => t.id),
        ...(this.roadmapData.shipped || []).map((t) => t.id)
      ]);
      const ideas = this.featuresData.filter((f) => !placedIds.has(f.id));

      let html = "";
      html += renderSection("Now", this.roadmapData.now, { allowVote: false });
      html += renderSection("Next", this.roadmapData.next, { dateField: "scheduled_for", allowVote: false });
      html += renderSection("Shipped", this.roadmapData.shipped, { dateField: "shipped_at", allowVote: false });
      html += renderSection("Ideas", ideas, { allowVote: true });
      if (!html) html = '<div class="ideabug-empty">Roadmap is empty so far.</div>';

      html +=
        '<div class="ideabug-footer">' +
        '<a class="ideabug-link" target="_blank" rel="noopener" href="' +
        this.config.apiHost +
        '/roadmap">Open public roadmap</a>' +
        "</div>";
      body.innerHTML = html;

      body.querySelectorAll('[data-action="toggle-vote"]').forEach((btn) => {
        btn.addEventListener("click", (e) => {
          e.stopPropagation();
          this.toggleVote(btn);
        });
      });
    }

    async toggleVote(btn) {
      const id = parseInt(btn.dataset.id, 10);
      if (this._voteLock[id]) return;
      this._voteLock[id] = true;
      setTimeout(() => { this._voteLock[id] = false; }, VOTE_DEBOUNCE_MS);

      const wasVoted = btn.classList.contains("is-voted");
      const countEl = btn.querySelector("span");
      const oldCount = parseInt(countEl.textContent, 10) || 0;
      btn.classList.toggle("is-voted", !wasVoted);
      countEl.textContent = String(wasVoted ? Math.max(0, oldCount - 1) : oldCount + 1);
      btn.querySelector("svg").outerHTML = heartSvg(!wasVoted);

      const res = wasVoted ? await this.client.unvote(id) : await this.client.vote(id);
      if (!res.ok || !res.data) {
        // Revert on failure
        btn.classList.toggle("is-voted", wasVoted);
        countEl.textContent = String(oldCount);
        btn.querySelector("svg").outerHTML = heartSvg(wasVoted);
        return;
      }
      countEl.textContent = String(res.data.votes_count);
      btn.classList.toggle("is-voted", !!res.data.voted_by_me);
      btn.querySelector("svg").outerHTML = heartSvg(!!res.data.voted_by_me);
    }
  }

  window.IdeabugWidget = new IdeabugWidget();

  // Back-compat shim for the legacy `new IdeabugNotifications({...})` API.
  window.IdeabugNotifications = function (config) {
    window.IdeabugWidget.configure({
      apiHost: config && config.apiHost,
      targetElement: config && config.targetElement,
      jwt: config && config.jwt,
      pollInterval: config && config.pollInterval
    });
    return window.IdeabugWidget;
  };

  // Note: the `ideabug:ready` event is dispatched by the bootstrap shell
  // (script.js) AFTER apiHost + targetElement are configured, so listeners
  // can safely call `IdeabugWidget.configure({ jwt: … })`.
})();
