/*
 * Kanalstandard – Aufbau und Werkzeuge des Workshop-Dokuments
 *
 * Rendert die in src/data.js aufgenommenen Quelldaten, filtert Layer- und
 * Linientyplisten und hält im Termin getroffene Eingaben (Schriftgrößen,
 * Beschlussstände, aus der XLSX eingefügte Eigenschaftswerte) lokal fest.
 * Es werden keine Werte erzeugt, die nicht aus den Quellen stammen oder
 * ausdrücklich eingetragen wurden.
 */

/* global window, document, navigator, localStorage, KANALSTANDARD */
(function () {
  'use strict';

  const D = window.KANALSTANDARD;
  if (!D) return;

  const ASSETS = 'assets/';
  const STORE_KEY = 'kanalstandard.v1';

  /* Beim Erzeugen der Einzeldatei (tools/build-standalone.mjs) werden die
     Anhänge als Data-URI hinterlegt; sonst wird aus assets/ geladen. */
  const EMBEDDED = window.KANALSTANDARD_ASSETS || {};
  const assetUrl = function (file) { return EMBEDDED[file] || ASSETS + file; };

  const STATUS_LABELS = {
    offen: 'offen',
    klaerung: 'in Klärung',
    entschieden: 'entschieden'
  };

  /* ---------------------------------------------------------- Werkzeuge -- */

  const $ = (sel, root) => (root || document).querySelector(sel);
  const $$ = (sel, root) => Array.prototype.slice.call((root || document).querySelectorAll(sel));

  function el(tag, attrs, children) {
    const node = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (key) {
        const value = attrs[key];
        if (value === null || value === undefined || value === false) return;
        if (key === 'class') node.className = value;
        else if (key === 'text') node.textContent = value;
        else if (key === 'html') node.innerHTML = value;
        else node.setAttribute(key, value === true ? '' : value);
      });
    }
    (children || []).forEach(function (child) {
      if (child === null || child === undefined) return;
      node.appendChild(typeof child === 'string' ? document.createTextNode(child) : child);
    });
    return node;
  }

  function fill(target, nodes) {
    const host = typeof target === 'string' ? $(target) : target;
    if (!host) return;
    host.textContent = '';
    nodes.forEach(function (node) { host.appendChild(node); });
  }

  function loadState() {
    try {
      return JSON.parse(localStorage.getItem(STORE_KEY) || '{}') || {};
    } catch (err) {
      return {};
    }
  }

  let state = loadState();

  function saveState() {
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify(state));
    } catch (err) {
      /* Speicherung ist optional – das Dokument bleibt auch ohne nutzbar. */
    }
  }

  function flash(node, message) {
    if (!node) return;
    node.textContent = message;
    window.setTimeout(function () { node.textContent = ''; }, 3200);
  }

  function copyText(text, statusNode, message) {
    const done = function () { flash(statusNode, message || 'In die Zwischenablage kopiert.'); };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(done, function () { fallbackCopy(text, done); });
    } else {
      fallbackCopy(text, done);
    }
  }

  function fallbackCopy(text, done) {
    const area = el('textarea', { 'aria-hidden': 'true' });
    area.value = text;
    area.style.position = 'fixed';
    area.style.opacity = '0';
    document.body.appendChild(area);
    area.select();
    try { document.execCommand('copy'); } catch (err) { /* ignoriert */ }
    document.body.removeChild(area);
    done();
  }

  function today() {
    const d = new Date();
    const pad = function (n) { return String(n).padStart(2, '0'); };
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
  }

  /* --------------------------------------------------------------- Bild -- */

  function mountImage(frame, file, alt, caption) {
    const img = el('img', { alt: alt, loading: 'lazy', src: assetUrl(file) });
    img.addEventListener('error', function () {
      frame.textContent = '';
      frame.removeAttribute('data-ready');
      frame.disabled = true;
      frame.style.cursor = 'default';
      frame.appendChild(el('div', { class: 'placeholder' }, [
        el('div', { text: 'Abbildung noch nicht im Ordner assets/ abgelegt' }),
        el('div', { class: 'placeholder__file', text: file })
      ]));
    });
    img.addEventListener('load', function () {
      frame.setAttribute('data-ready', 'true');
      frame.dataset.caption = caption || alt;
      frame.dataset.src = img.src;
    });
    frame.textContent = '';
    frame.appendChild(img);
  }

  function figureCard(fig) {
    const frame = el('button', { class: 'figure__frame', type: 'button', 'aria-label': fig.title + ' vergrößern' });
    mountImage(frame, fig.file, fig.title, 'Originalbild ' + fig.id + ' · ' + fig.title);
    return el('div', { class: 'figure' }, [
      frame,
      el('div', { class: 'figure__body' }, [
        el('p', { class: 'figure__meta', text: 'Originalbild ' + fig.id + ' · ' + fig.source }),
        el('h3', { class: 'figure__title', text: fig.title }),
        el('p', { class: 'figure__text', text: fig.text })
      ])
    ]);
  }

  function initLightbox() {
    const dialog = $('#lightbox');
    const img = $('#lightbox-img');
    const caption = $('#lightbox-caption');
    if (!dialog || !img) return;

    document.addEventListener('click', function (event) {
      const frame = event.target.closest ? event.target.closest('.figure__frame') : null;
      if (!frame || frame.getAttribute('data-ready') !== 'true') return;
      img.src = frame.dataset.src;
      img.alt = frame.dataset.caption || '';
      caption.textContent = frame.dataset.caption || '';
      if (typeof dialog.showModal === 'function') dialog.showModal();
    });

    $('#lightbox-close').addEventListener('click', function () { dialog.close(); });
    dialog.addEventListener('click', function (event) {
      if (event.target === dialog || event.target.classList.contains('lightbox__inner')) dialog.close();
    });
  }

  /* ------------------------------------------------------- Kopf und Nav -- */

  function renderBadges() {
    const badges = [
      { text: D.figures.length + ' Originalbilder eingebettet', kind: 'done' },
      { text: D.layerManager.length + ' Layerdatensätze vollständig aufgenommen', kind: 'done' },
      { text: D.linetypeTotal + ' Linientypen ergänzt', kind: 'done' },
      { text: 'PDF + XLSX als Anhang verlinkt', kind: '' },
      { text: 'Schriftgrößen 1:250 / 1:500 offen', kind: 'open' },
      { text: 'Klassisches Design offen', kind: 'open' }
    ];
    fill('#hero-badges', badges.map(function (badge) {
      return el('li', { class: 'badge' + (badge.kind ? ' badge--' + badge.kind : '') }, [
        el('span', { class: 'badge__dot', 'aria-hidden': 'true' }),
        document.createTextNode(badge.text)
      ]);
    }));
  }

  function renderNav() {
    const sections = $$('main section[data-nav]');
    fill('#nav-list', sections.map(function (section) {
      return el('li', {}, [
        el('a', { class: 'nav__link', href: '#' + section.id, text: section.dataset.nav })
      ]);
    }));

    if (!('IntersectionObserver' in window)) return;
    const links = {};
    $$('#nav-list .nav__link').forEach(function (link) { links[link.getAttribute('href').slice(1)] = link; });

    const observer = new window.IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        const link = links[entry.target.id];
        if (!link) return;
        if (entry.isIntersecting) {
          Object.keys(links).forEach(function (id) { links[id].removeAttribute('aria-current'); });
          link.setAttribute('aria-current', 'true');
        }
      });
    }, { rootMargin: '-60px 0px -70% 0px', threshold: 0 });

    sections.forEach(function (section) { observer.observe(section); });
  }

  function initChrome() {
    const themeBtn = $('#toggle-theme');
    const applyTheme = function (theme) {
      document.documentElement.setAttribute('data-theme', theme);
      themeBtn.textContent = theme === 'dark' ? 'Hell' : 'Dunkel';
      themeBtn.setAttribute('aria-pressed', theme === 'dark' ? 'true' : 'false');
    };
    applyTheme(state.theme === 'dark' ? 'dark' : 'light');
    themeBtn.addEventListener('click', function () {
      state.theme = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      applyTheme(state.theme);
      saveState();
    });

    const allBtn = $('#toggle-all');
    allBtn.addEventListener('click', function () {
      const open = allBtn.getAttribute('aria-pressed') !== 'true';
      $$('details.panel--group').forEach(function (node) { node.open = open; });
      allBtn.setAttribute('aria-pressed', open ? 'true' : 'false');
      allBtn.textContent = open ? 'Alle Gruppen schließen' : 'Alle Gruppen öffnen';
    });

    $('#print-doc').addEventListener('click', function () {
      $$('details').forEach(function (node) { node.open = true; });
      window.print();
    });

    $('#footer-meta').textContent =
      D.layerManager.length + ' Layer · ' + D.linetypeTotal + ' Linientypen · ' + D.figures.length + ' Abbildungen';
  }

  /* ------------------------------------------------------ Prosaabschnitte -- */

  function renderContext() {
    fill('#original-message', D.originalMessage.map(function (para) {
      return el('p', { text: para });
    }));

    fill('#work-requirements', D.workRequirements.map(function (item) {
      return el('li', { text: item });
    }));

    fill('#modules', D.modules.map(function (mod) {
      return el('div', { class: 'module' }, [
        el('h3', { class: 'module__title', text: 'Modul ' + mod.nr + ' – ' + mod.title }),
        el('p', { class: 'module__text', text: mod.text })
      ]);
    }));

    fill('#agenda', D.agenda.map(function (row) {
      return el('div', { class: 'timeline__row' }, [
        el('div', { class: 'timeline__time', text: row.time + '\nMin.' }),
        el('div', {}, [
          el('div', { class: 'timeline__title', text: row.title }),
          el('p', { class: 'timeline__text', text: row.text })
        ])
      ]);
    }));

    fill('#types-main', D.channelTypesMain.map(function (type) {
      return el('li', {}, [el('strong', { text: type.name }), document.createTextNode(' – ' + type.text)]);
    }));

    fill('#types-special', D.channelTypesSpecial.map(function (item) {
      return el('li', { text: item });
    }));

    fill('#block-parts', D.blockParts.map(function (item) { return el('li', { text: item }); }));
    fill('#findings', D.findings.map(function (item) { return el('li', { text: item }); }));

    fill('#attachments', D.attachments.map(function (att) {
      return el('a', { class: 'attachment', href: assetUrl(att.file), download: att.file }, [
        el('span', { class: 'attachment__label', text: att.label }),
        el('span', { class: 'attachment__file', text: att.file }),
        el('span', { class: 'attachment__note', text: att.note })
      ]);
    }));
  }

  function chip(text, extra) {
    return el('li', {}, [el('span', { class: 'chip' + (extra ? ' ' + extra : ''), text: text })]);
  }

  function renderChips() {
    fill('#kanpl-layers', D.kanplLayers.map(function (name) { return chip(name); }));
    fill('#bver-layers', D.bverLayers.map(function (name) { return chip(name); }));
    fill('#blocks-planung', D.blocks.planung.map(function (name) { return chip(name, 'chip--block'); }));
    fill('#blocks-bestand', D.blocks.bestand.map(function (name) { return chip(name, 'chip--block'); }));
  }

  /* ----------------------------------------------------- Bilderabschnitte -- */

  function renderFigures() {
    const bySection = function (key) {
      return D.figures.filter(function (fig) { return fig.section === key; });
    };
    fill('#figures-kanal', bySection('kanal').map(figureCard));
    fill('#figures-linientypen', bySection('linientypen').map(figureCard));
    fill('#figures-farben', bySection('farben').map(figureCard));

    const overviewFrame = $('[data-lightbox="overview"]');
    if (overviewFrame) {
      mountImage(overviewFrame, D.overviewFigure.file, D.overviewFigure.title, D.overviewFigure.title);
    }
    $('#overview-text').textContent = D.overviewFigure.text;
    $('#overview-priority').textContent = D.overviewFigure.priority;
  }

  /* ------------------------------------------------ Layerstruktur Bestand -- */

  function renderBkanGroups() {
    const total = D.bkanGroups.reduce(function (sum, group) { return sum + group.layers.length; }, 0);

    fill('#bkan-groups', D.bkanGroups.map(function (group) {
      return el('details', { class: 'panel panel--group', open: true }, [
        el('summary', {}, [
          document.createTextNode(group.title),
          el('span', { class: 'panel__count', text: group.layers.length + ' Layer' })
        ]),
        el('ul', { class: 'layer-list' }, group.layers.map(function (name) {
          return el('li', { text: name, 'data-layer': name.toLowerCase() });
        }))
      ]);
    }));

    const countNode = $('#bkan-count');
    const input = $('#bkan-filter');

    const update = function () {
      const term = input.value.trim().toLowerCase();
      let visible = 0;
      $$('#bkan-groups details').forEach(function (group) {
        let groupVisible = 0;
        $$('li[data-layer]', group).forEach(function (item) {
          const match = !term || item.dataset.layer.indexOf(term) !== -1;
          item.hidden = !match;
          if (match) groupVisible += 1;
        });
        group.hidden = groupVisible === 0;
        if (term && groupVisible > 0) group.open = true;
        visible += groupVisible;
      });
      countNode.textContent = term
        ? visible + ' von ' + total + ' Zuordnungen sichtbar'
        : total + ' Zuordnungen in ' + D.bkanGroups.length + ' Objektgruppen (Mehrfachzuordnung möglich)';
    };

    input.addEventListener('input', update);
    update();
  }

  /* ---------------------------------------------------- Maßstabsmatrix -- */

  function renderMatrix() {
    const body = $('#matrix-body');
    const countNode = $('#matrix-count');
    const statusNode = $('#matrix-status');

    const updateCount = function () {
      const filled = D.scaleMatrix.reduce(function (sum, row) {
        const entry = state.matrix[row.key] || {};
        return sum + (entry['250'] ? 1 : 0) + (entry['500'] ? 1 : 0);
      }, 0);
      const total = D.scaleMatrix.length * 2;
      countNode.textContent = filled + ' von ' + total + ' Schriftgrößen festgelegt';
    };

    const draw = function () {
      state.matrix = state.matrix || {};
      fill(body, D.scaleMatrix.map(function (row) {
        const cells = ['250', '500'].map(function (scale) {
          const input = el('input', {
            class: 'cellinput',
            type: 'text',
            value: (state.matrix[row.key] || {})[scale] || '',
            placeholder: 'festzulegen',
            'aria-label': row.subject + ' – Schriftgröße 1:' + scale
          });
          input.addEventListener('input', function () {
            state.matrix[row.key] = state.matrix[row.key] || {};
            state.matrix[row.key][scale] = input.value;
            saveState();
            updateCount();
          });
          return el('td', { class: 'scale' }, [input]);
        });

        return el('tr', {}, [
          el('td', { class: 'subject', text: row.subject }),
          el('td', { class: 'content', text: row.content })
        ].concat(cells));
      }));
      updateCount();
    };

    draw();

    $('#matrix-export').addEventListener('click', function () {
      const lines = [
        '| Darstellungsgegenstand | Inhalte / Funktion | 1:250 | 1:500 |',
        '| --- | --- | --- | --- |'
      ];
      D.scaleMatrix.forEach(function (row) {
        const entry = state.matrix[row.key] || {};
        lines.push('| ' + row.subject + ' | ' + row.content + ' | ' +
          (entry['250'] || 'festzulegen') + ' | ' + (entry['500'] || 'festzulegen') + ' |');
      });
      copyText(lines.join('\n'), statusNode, 'Matrix kopiert.');
    });

    $('#matrix-reset').addEventListener('click', function () {
      state.matrix = {};
      saveState();
      draw();
      flash(statusNode, 'Eingaben zurückgesetzt.');
    });
  }

  /* ------------------------------------------------------- Layer-Manager -- */

  function familyOf(name) {
    if (name.indexOf('BKAN') === 0) return 'BKAN';
    if (name.indexOf('BVER') === 0) return 'BVER';
    return 'REST';
  }

  function layerProps(name) {
    const stored = (state.layerProps || {})[name];
    return stored || null;
  }

  function renderLayerManager() {
    const rows = D.layerManager;
    const counts = { BKAN: 0, BVER: 0, REST: 0 };
    rows.forEach(function (row) { counts[familyOf(row.name)] += 1; });
    $('#lm-bkan').textContent = counts.BKAN;
    $('#lm-bver').textContent = counts.BVER;
    $('#lm-rest').textContent = counts.REST;

    fill('#lm-head', [el('th', { scope: 'col', text: 'Nr.' }), el('th', { scope: 'col', text: 'Name' })]
      .concat(D.layerColumns.map(function (col) { return el('th', { scope: 'col', text: col }); })));

    const body = $('#lm-body');

    const draw = function () {
      const term = $('#lm-filter').value.trim().toLowerCase();
      const family = $('#lm-family').value;
      let visible = 0;

      fill(body, rows.filter(function (row) {
        if (family && familyOf(row.name) !== family) return false;
        if (term && row.name.toLowerCase().indexOf(term) === -1) return false;
        return true;
      }).map(function (row) {
        visible += 1;
        const stored = layerProps(row.name) || row.props || {};
        const cells = D.layerColumns.map(function (col) {
          const value = stored[col];
          return value
            ? el('td', { text: value })
            : el('td', {}, [el('span', { class: 'todo', title: 'aus der XLSX zu übernehmen', text: '–' })]);
        });
        return el('tr', {}, [
          el('td', { class: 'nr', text: row.nr }),
          el('td', { class: 'name', text: row.name })
        ].concat(cells));
      }));

      const withValues = rows.filter(function (row) { return layerProps(row.name); }).length;
      $('#lm-count').textContent = visible + ' von ' + rows.length + ' Datensätzen sichtbar · ' +
        withValues + ' mit übernommenen Eigenschaftswerten';
    };

    $('#lm-filter').addEventListener('input', draw);
    $('#lm-family').addEventListener('change', draw);
    draw();
    return draw;
  }

  /* -------------------------------------------------------- Linientypen -- */

  function linetypeGroupOf(name) {
    const upper = name.toUpperCase();
    if (upper.indexOf('ENTW') === 0) return 'ENTW';
    if (upper.indexOf('GP') === 0) return 'GP';
    if (upper.indexOf('LEV') === 0) return 'LEV';
    if (upper.indexOf('MARK') === 0) return 'MARK';
    if (upper.indexOf('VERS') === 0) return 'VERS';
    if (upper.indexOf('ZAUN') === 0) return 'ZAUN';
    if (upper.indexOf('HOEHE') === 0 || upper.indexOf('HÖHE') === 0) return 'HOEHEN';
    return 'SONSTIGE';
  }

  function currentLinetypes() {
    return (state.linetypes && state.linetypes.length) ? state.linetypes : D.linetypes;
  }

  function renderLinetypes() {
    const groupLabels = {};
    D.linetypeGroups.forEach(function (group) { groupLabels[group.key] = group.label; });

    fill('#lt-groups', D.linetypeGroups.map(function (group) {
      return el('li', {}, [
        el('span', { class: 'chip', text: group.label }),
        el('span', { class: 'chip chip--muted', text: group.note })
      ]);
    }));

    fill('#lt-notes', D.linetypeNotes.map(function (note) {
      return el('div', { class: 'note-panel', style: 'margin-top:14px', text: note });
    }));

    const body = $('#lt-body');

    const draw = function () {
      const list = currentLinetypes();
      const term = $('#lt-filter').value.trim().toLowerCase();
      let visible = 0;

      fill(body, list.filter(function (item) {
        if (!term) return true;
        return (item.name + ' ' + (item.desc || '')).toLowerCase().indexOf(term) !== -1;
      }).map(function (item) {
        visible += 1;
        const group = item.group || linetypeGroupOf(item.name);
        return el('tr', {}, [
          el('td', { class: 'name', text: item.name }),
          el('td', { class: 'pattern', text: item.pattern || '–' }),
          el('td', { text: item.desc || '–' }),
          el('td', {}, [el('span', { class: 'tag', text: groupLabels[group] || group })])
        ]);
      }));

      $('#lt-total').textContent = D.linetypeTotal;
      $('#lt-captured').textContent = list.length;
      $('#lt-count').textContent = visible + ' von ' + list.length + ' aufgenommenen Linientypen sichtbar';

      const gap = D.linetypeTotal - list.length;
      const gapNode = $('#lt-gap');
      if (gap > 0) {
        gapNode.hidden = false;
        gapNode.textContent = 'Noch zu übernehmen: ' + gap + ' der ' + D.linetypeTotal +
          ' Linientypen sind bisher nur in den Screenshots belegt und nicht namentlich erfasst. ' +
          'Die vollständige Liste lässt sich unten aus dem Linientyp-Manager beziehungsweise der .lin-Datei einfügen; ' +
          'Namen werden dabei nicht erraten.';
      } else {
        gapNode.hidden = true;
      }
    };

    $('#lt-filter').addEventListener('input', draw);
    draw();
    return draw;
  }

  /* -------------------------------------------------------------- Farben -- */

  function renderColors() {
    fill('#color-swatches', D.colors.reduce(function (nodes, color) {
      nodes.push(el('div', { class: 'swatch' }, [
        el('div', { class: 'swatch__chip', style: 'background:' + color.css, 'aria-hidden': 'true' }),
        el('div', {}, [
          el('div', { class: 'swatch__title', text: 'Indexfarbe' }),
          el('p', { class: 'swatch__text' }, [
            el('span', { class: 'swatch__value', text: color.name }),
            document.createTextNode(' – ' + color.index)
          ])
        ])
      ]));
      nodes.push(el('div', { class: 'swatch' }, [
        el('div', { class: 'swatch__chip', style: 'background:' + color.css, 'aria-hidden': 'true' }),
        el('div', {}, [
          el('div', { class: 'swatch__title', text: 'True Color' }),
          el('p', { class: 'swatch__text', text: color.truecolor })
        ])
      ]));
      return nodes;
    }, []));
  }

  /* --------------------------------------------------------- Beschlüsse -- */

  function decisionState(key) {
    state.decisions = state.decisions || {};
    state.decisions[key] = state.decisions[key] || { status: 'offen', note: '' };
    return state.decisions[key];
  }

  function renderDecisions() {
    const host = $('#decisions');
    const countNode = $('#dec-count');
    const statusNode = $('#dec-status');

    const updateCount = function () {
      const filterValue = $('#dec-filter').value;
      const tally = { offen: 0, klaerung: 0, entschieden: 0 };
      D.decisions.forEach(function (dec) { tally[decisionState(dec.key).status] += 1; });
      let visible = 0;
      $$('.decision', host).forEach(function (node) {
        const match = !filterValue || node.dataset.status === filterValue;
        node.hidden = !match;
        if (match) visible += 1;
      });
      countNode.textContent = visible + ' von ' + D.decisions.length + ' Punkten sichtbar · ' +
        tally.offen + ' offen, ' + tally.klaerung + ' in Klärung, ' + tally.entschieden + ' entschieden';
    };

    const draw = function () {
      fill(host, D.decisions.map(function (dec) {
        const current = decisionState(dec.key);

        const select = el('select', { 'aria-label': 'Status: ' + dec.title });
        Object.keys(STATUS_LABELS).forEach(function (value) {
          select.appendChild(el('option', { value: value, text: STATUS_LABELS[value] }));
        });
        select.value = current.status;

        const note = el('textarea', {
          class: 'decision__note',
          placeholder: 'Beschluss, Verantwortliche oder Rückfrage notieren …',
          'aria-label': 'Notiz zu: ' + dec.title
        });
        note.value = current.note;

        const card = el('div', { class: 'decision', 'data-status': current.status }, [
          el('div', { class: 'decision__head' }, [
            el('div', { class: 'decision__title', text: dec.title }),
            el('span', { class: 'decision__module', text: dec.module }),
            select
          ]),
          el('p', { class: 'decision__text', text: dec.text }),
          note
        ]);

        select.addEventListener('change', function () {
          decisionState(dec.key).status = select.value;
          card.dataset.status = select.value;
          saveState();
          updateCount();
        });

        note.addEventListener('input', function () {
          decisionState(dec.key).note = note.value;
          saveState();
        });

        return card;
      }));
      updateCount();
    };

    draw();

    $('#dec-filter').addEventListener('change', updateCount);

    $('#dec-reset').addEventListener('click', function () {
      state.decisions = {};
      saveState();
      draw();
      flash(statusNode, 'Beschlussstand zurückgesetzt.');
    });

    $('#dec-export').addEventListener('click', function () {
      copyText(decisionMarkdown(), statusNode, 'Protokoll kopiert.');
    });

    $('#dec-download').addEventListener('click', function () {
      const blob = new window.Blob([decisionMarkdown()], { type: 'text/markdown;charset=utf-8' });
      const url = window.URL.createObjectURL(blob);
      const link = el('a', { href: url, download: 'kanalstandard-beschlussliste-' + today() + '.md' });
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
      flash(statusNode, 'Protokoll heruntergeladen.');
    });
  }

  function decisionMarkdown() {
    const lines = ['# Kanalstandard – Beschlussliste', '', 'Stand: ' + today(), ''];
    Object.keys(STATUS_LABELS).forEach(function (status) {
      const group = D.decisions.filter(function (dec) { return decisionState(dec.key).status === status; });
      if (!group.length) return;
      lines.push('## ' + STATUS_LABELS[status] + ' (' + group.length + ')', '');
      group.forEach(function (dec) {
        lines.push('- **' + dec.title + '** · ' + dec.module);
        lines.push('  - ' + dec.text);
        const note = decisionState(dec.key).note.trim();
        if (note) lines.push('  - Notiz: ' + note.replace(/\n+/g, ' '));
      });
      lines.push('');
    });

    const filled = D.scaleMatrix.filter(function (row) {
      const entry = (state.matrix || {})[row.key] || {};
      return entry['250'] || entry['500'];
    });
    if (filled.length) {
      lines.push('## Festgelegte Schriftgrößen', '', '| Gegenstand | 1:250 | 1:500 |', '| --- | --- | --- |');
      filled.forEach(function (row) {
        const entry = state.matrix[row.key];
        lines.push('| ' + row.subject + ' | ' + (entry['250'] || 'offen') + ' | ' + (entry['500'] || 'offen') + ' |');
      });
      lines.push('');
    }

    return lines.join('\n');
  }

  /* ------------------------------------------------------ Master-Prompt -- */

  function renderPrompt() {
    $('#prompt-text').textContent = D.masterPrompt;
    const status = $('#prompt-status');

    $('#prompt-copy').addEventListener('click', function () {
      copyText(D.masterPrompt, status, 'Master-Prompt kopiert.');
    });

    $('#prompt-copy-state').addEventListener('click', function () {
      const text = D.masterPrompt + '\n\nAKTUELLER BESCHLUSSSTAND (' + today() + ')\n' + decisionMarkdown();
      copyText(text, status, 'Master-Prompt mit Beschlussstand kopiert.');
    });
  }

  /* -------------------------------------------------------- Quelldaten -- */

  function parseTable(raw) {
    return raw.split(/\r?\n/)
      .map(function (line) { return line.trim(); })
      .filter(function (line) { return line.length > 0; })
      .map(function (line) {
        const delimiter = line.indexOf('\t') !== -1 ? '\t' : (line.indexOf(';') !== -1 ? ';' : ',');
        return line.split(delimiter).map(function (cell) { return cell.trim(); });
      })
      .filter(function (cells, index) {
        if (index !== 0) return true;
        const first = (cells[0] || '').toLowerCase();
        return first !== 'name' && first !== 'nr.' && first !== 'nr' && first !== 'linientyp';
      });
  }

  function initImports(redrawLayers, redrawLinetypes) {
    const statusOf = function (kind) { return $('[data-import-status="' + kind + '"]'); };

    $('[data-import-apply="layer"]').addEventListener('click', function () {
      const parsed = parseTable($('#layer-import-input').value);
      const known = {};
      D.layerManager.forEach(function (row) { known[row.name.toLowerCase()] = row.name; });

      const props = {};
      let matched = 0;
      let unknown = 0;
      parsed.forEach(function (cells) {
        const name = known[(cells[0] || '').toLowerCase()];
        if (!name) { if (cells[0]) unknown += 1; return; }
        const entry = {};
        D.layerColumns.forEach(function (col, index) {
          const value = cells[index + 1];
          if (value) entry[col] = value;
        });
        props[name] = entry;
        matched += 1;
      });

      state.layerProps = Object.assign({}, state.layerProps || {}, props);
      saveState();
      redrawLayers();
      flash(statusOf('layer'), matched + ' Layer übernommen' + (unknown ? ', ' + unknown + ' unbekannte Namen ignoriert' : '') + '.');
    });

    $('[data-import-clear="layer"]').addEventListener('click', function () {
      state.layerProps = {};
      saveState();
      redrawLayers();
      flash(statusOf('layer'), 'Übernommene Werte gelöscht.');
    });

    $('[data-import-dump="layer"]').addEventListener('click', function () {
      const entries = Object.keys(state.layerProps || {});
      if (!entries.length) { flash(statusOf('layer'), 'Noch keine Werte übernommen.'); return; }
      const lines = entries.sort().map(function (name) {
        return '    ' + JSON.stringify({ name: name, props: state.layerProps[name] }) + ',';
      });
      copyText('  // in src/data.js in LAYER_MANAGER übernehmen\n' + lines.join('\n'),
        statusOf('layer'), entries.length + ' Datensätze als data.js-Block kopiert.');
    });

    $('[data-import-apply="linetype"]').addEventListener('click', function () {
      const parsed = parseTable($('#linetype-import-input').value);
      const list = parsed.filter(function (cells) { return cells[0]; }).map(function (cells) {
        return {
          name: cells[0],
          desc: cells[1] || '–',
          pattern: cells[2] || '',
          group: cells[3] || linetypeGroupOf(cells[0])
        };
      });
      if (!list.length) { flash(statusOf('linetype'), 'Keine verwertbaren Zeilen erkannt.'); return; }
      state.linetypes = list;
      saveState();
      redrawLinetypes();
      flash(statusOf('linetype'), list.length + ' Linientypen übernommen.');
    });

    $('[data-import-clear="linetype"]').addEventListener('click', function () {
      state.linetypes = null;
      saveState();
      redrawLinetypes();
      flash(statusOf('linetype'), 'Übernommene Liste gelöscht.');
    });

    $('[data-import-dump="linetype"]').addEventListener('click', function () {
      if (!state.linetypes || !state.linetypes.length) {
        flash(statusOf('linetype'), 'Noch keine Liste übernommen.');
        return;
      }
      const lines = state.linetypes.map(function (item) { return '    ' + JSON.stringify(item) + ','; });
      copyText('  // in src/data.js in LINETYPES übernehmen\n' + lines.join('\n'),
        statusOf('linetype'), state.linetypes.length + ' Linientypen als data.js-Block kopiert.');
    });
  }

  /* ---------------------------------------------------------------- Start -- */

  renderBadges();
  renderNav();
  initChrome();
  renderContext();
  renderChips();
  renderFigures();
  renderBkanGroups();
  renderMatrix();
  const redrawLayers = renderLayerManager();
  const redrawLinetypes = renderLinetypes();
  renderColors();
  renderDecisions();
  renderPrompt();
  initImports(redrawLayers, redrawLinetypes);
  initLightbox();
})();
