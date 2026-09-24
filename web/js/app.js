/**
 * BEAD5 — Five Moments. One Journey.
 * Official Digital Campaign & Interactive Platform Engine
 * Jesus Youth — Pazhassiraja College
 */

// ==========================================
// 1. CONFIGURATION & STATE MANAGEMENT
// ==========================================

const DEFAULT_SCHEDULE = [
  { id: 1, moment: '01', timeStr: '11:00', label: '11:00 AM', decade: 1, title: 'First Decade', windowMinutes: 30 },
  { id: 2, moment: '02', timeStr: '12:05', label: '12:05 PM', decade: 2, title: 'Second Decade', windowMinutes: 30 },
  { id: 3, moment: '03', timeStr: '13:00', label: '1:00 PM', decade: 3, title: 'Third Decade', windowMinutes: 45 },
  { id: 4, moment: '04', timeStr: '14:00', label: '2:00 PM', decade: 4, title: 'Fourth Decade', windowMinutes: 30 },
  { id: 5, moment: '05', timeStr: '15:00', label: '3:00 PM', decade: 5, title: 'Fifth Decade', windowMinutes: 30 }
];

const MYSTERIES_DATA = {
  joyful: {
    name: 'Joyful Mysteries',
    days: 'Mondays & Saturdays',
    decades: [
      { num: 1, title: 'The Annunciation', fruit: 'Humility', verse: 'Luke 1:26-38 — "Behold, I am the handmaid of the Lord."' },
      { num: 2, title: 'The Visitation', fruit: 'Love of Neighbor', verse: 'Luke 1:39-56 — "Blessed are you among women, and blessed is the fruit of your womb."' },
      { num: 3, title: 'The Nativity', fruit: 'Poverty of Spirit', verse: 'Luke 2:1-20 — "And she gave birth to her firstborn son and wrapped him in swaddling cloths."' },
      { num: 4, title: 'The Presentation', fruit: 'Obedience', verse: 'Luke 2:22-38 — "For my eyes have seen your salvation."' },
      { num: 5, title: 'The Finding in the Temple', fruit: 'Joy in Finding Jesus', verse: 'Luke 2:41-52 — "Did you not know that I must be in my Father\'s house?"' }
    ]
  },
  luminous: {
    name: 'Luminous Mysteries',
    days: 'Thursdays',
    decades: [
      { num: 1, title: 'The Baptism in the Jordan', fruit: 'Openness to the Holy Spirit', verse: 'Matthew 3:13-17 — "This is my beloved Son, with whom I am well pleased."' },
      { num: 2, title: 'The Wedding at Cana', fruit: 'To Jesus through Mary', verse: 'John 2:1-12 — "Do whatever he tells you."' },
      { num: 3, title: 'Proclamation of the Kingdom', fruit: 'Repentance & Trust', verse: 'Mark 1:14-15 — "The time is fulfilled, and the kingdom of God is at hand."' },
      { num: 4, title: 'The Transfiguration', fruit: 'Desire for Holiness', verse: 'Matthew 17:1-8 — "And he was transfigured before them, his face shone like the sun."' },
      { num: 5, title: 'Institution of the Eucharist', fruit: 'Eucharistic Devotion', verse: 'Matthew 26:26-28 — "Take, eat; this is my body."' }
    ]
  },
  sorrowful: {
    name: 'Sorrowful Mysteries',
    days: 'Tuesdays & Fridays',
    decades: [
      { num: 1, title: 'Agony in the Garden', fruit: 'Contrition for Sins', verse: 'Matthew 26:36-46 — "Not as I will, but as you will."' },
      { num: 2, title: 'Scourging at the Pillar', fruit: 'Purity & Mortification', verse: 'Matthew 27:26 — "Then he released for them Barabbas, and having scourged Jesus, delivered him to be crucified."' },
      { num: 3, title: 'Crowning with Thorns', fruit: 'Moral Courage', verse: 'Matthew 27:27-31 — "And twisting together a crown of thorns, they put it on his head."' },
      { num: 4, title: 'Carrying of the Cross', fruit: 'Patience in Suffering', verse: 'John 19:17 — "So they took Jesus, and he went out, bearing his own cross."' },
      { num: 5, title: 'The Crucifixion', fruit: 'Salvation & Forgiveness', verse: 'Luke 23:33-46 — "Father, forgive them, for they know not what they do."' }
    ]
  },
  glorious: {
    name: 'Glorious Mysteries',
    days: 'Wednesdays & Sundays',
    decades: [
      { num: 1, title: 'The Resurrection', fruit: 'Faith', verse: 'Mark 16:1-8 — "He is risen; he is not here."' },
      { num: 2, title: 'The Ascension', fruit: 'Hope', verse: 'Acts 1:9-11 — "He was lifted up, and a cloud took him out of their sight."' },
      { num: 3, title: 'Descent of the Holy Spirit', fruit: 'Love of God & Zeal', verse: 'Acts 2:1-4 — "And they were all filled with the Holy Spirit."' },
      { num: 4, title: 'The Assumption of Mary', fruit: 'Grace of a Happy Death', verse: 'Revelation 12:1 — "A great sign appeared in heaven: a woman clothed with the sun."' },
      { num: 5, title: 'The Coronation of Mary', fruit: 'Trust in Mary\'s Intercession', verse: 'Judith 15:9 — "You are the highest honor of our race."' }
    ]
  }
};

let appState = {
  schedule: JSON.parse(localStorage.getItem('bead5_schedule')) || DEFAULT_SCHEDULE,
  prayedDecades: JSON.parse(localStorage.getItem('bead5_prayed_today')) || [],
  activeMysterySet: getMysterySetForToday(),
  currentSimulatedTime: null, // null means use real clock
  activePrayingDecade: 1,
  currentBeadCount: 0,
  audioMuted: false
};

// ==========================================
// 2. AUDIO SYNTHESIZER (PRAYER BELL CHIME)
// ==========================================

let audioCtx = null;

function playPrayerChime() {
  if (appState.audioMuted) return;
  try {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    if (!audioCtx) audioCtx = new AudioContext();
    if (audioCtx.state === 'suspended') audioCtx.resume();

    const now = audioCtx.currentTime;
    
    // Fundamental warm Tibetan/monastic bell chime
    const osc1 = audioCtx.createOscillator();
    const osc2 = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();

    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(587.33, now); // D5
    
    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(880, now); // A5 harmonic

    gainNode.gain.setValueAtTime(0.001, now);
    gainNode.gain.exponentialRampToValueAtTime(0.25, now + 0.04);
    gainNode.gain.exponentialRampToValueAtTime(0.0001, now + 1.8);

    osc1.connect(gainNode);
    osc2.connect(gainNode);
    gainNode.connect(audioCtx.destination);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 1.85);
    osc2.stop(now + 1.85);
  } catch (e) {
    console.warn('Audio chime notice:', e);
  }
}

// ==========================================
// 3. INTRO ANIMATION (Section 25)
// ==========================================

function initIntroAnimation() {
  const curtain = document.getElementById('intro-curtain');
  const beads = document.querySelectorAll('.curtain-bead');
  const content = document.querySelector('.curtain-content');
  const skipBtn = document.getElementById('skip-intro-btn');

  const hasSeenIntro = sessionStorage.getItem('bead5_seen_intro');
  if (hasSeenIntro) {
    if (curtain) curtain.classList.add('hidden');
    return;
  }

  // Sequentially illuminate beads
  beads.forEach((bead, idx) => {
    setTimeout(() => {
      bead.classList.add('active');
      playPrayerChime();
    }, 400 + idx * 450);
  });

  // Reveal BEAD5 lockup
  setTimeout(() => {
    if (content) content.classList.add('show-text');
  }, 2600);

  // Auto dismiss curtain
  const timer = setTimeout(() => {
    finishIntro();
  }, 4400);

  function finishIntro() {
    clearTimeout(timer);
    if (curtain) {
      curtain.classList.add('hidden');
      sessionStorage.setItem('bead5_seen_intro', 'true');
    }
  }

  if (skipBtn) {
    skipBtn.addEventListener('click', finishIntro);
  }
}

// ==========================================
// 4. LIVE MOMENT & TIME ENGINE (Section 06, 18, 19, 20)
// ==========================================

function getMysterySetForToday() {
  const day = new Date().getDay(); // 0 = Sun, 1 = Mon, ..., 6 = Sat
  if (day === 1 || day === 6) return 'joyful';
  if (day === 2 || day === 5) return 'sorrowful';
  if (day === 4) return 'luminous';
  return 'glorious';
}

function getEffectiveNow() {
  if (appState.currentSimulatedTime) {
    return new Date(appState.currentSimulatedTime);
  }
  return new Date();
}

function updateLiveEngine() {
  const now = getEffectiveNow();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();

  let activeMoment = null;
  let nextMoment = null;
  let smallestDiff = Infinity;

  appState.schedule.forEach(slot => {
    const [h, m] = slot.timeStr.split(':').map(Number);
    const slotMinutes = h * 60 + m;
    const diff = slotMinutes - currentMinutes;

    // Check if slot is active right now (from slot start to windowMinutes after)
    if (currentMinutes >= slotMinutes && currentMinutes <= slotMinutes + slot.windowMinutes) {
      activeMoment = slot;
    }

    // Check next upcoming slot
    if (diff > 0 && diff < smallestDiff) {
      smallestDiff = diff;
      nextMoment = slot;
    }
  });

  renderSmartCard(activeMoment, nextMoment, now);
  renderFiveBeadMeters();
  renderTimelineHighlight(activeMoment);
}

function renderSmartCard(active, next, now) {
  const overlineEl = document.getElementById('smart-moment-overline');
  const titleEl = document.getElementById('smart-moment-title');
  const messageEl = document.getElementById('smart-moment-msg');
  const countdownEl = document.getElementById('smart-countdown-display');
  const actionBtn = document.getElementById('smart-action-btn');
  const actionLabel = document.getElementById('smart-action-label');
  const completeCountEl = document.getElementById('smart-completed-count');

  if (!overlineEl || !titleEl) return;

  const count = appState.prayedDecades.length;
  if (completeCountEl) completeCountEl.textContent = `${count} / 5 Moments`;

  // Update bead nodes in smart card
  const beadNodes = document.querySelectorAll('.smart-bead-item');
  beadNodes.forEach((item, index) => {
    const decadeNum = index + 1;
    item.classList.remove('completed', 'active');
    if (appState.prayedDecades.includes(decadeNum)) {
      item.classList.add('completed');
    } else if (active && active.decade === decadeNum) {
      item.classList.add('active');
    }
  });

  // State A: All 5 completed
  if (count >= 5) {
    overlineEl.textContent = 'JOURNEY COMPLETE';
    titleEl.textContent = 'You completed the five moments.';
    messageEl.innerHTML = 'Five decades. One Rosary. One journey of prayer.<br><strong>BEAD5 — Five Moments. One Journey.</strong>';
    countdownEl.innerHTML = 'Completed for today';
    if (actionLabel) actionLabel.textContent = 'VIEW JOURNEY CERTIFICATE';
    if (actionBtn) {
      actionBtn.onclick = () => openCertificateModal();
    }
    return;
  }

  // State B: Active Moment right now
  if (active) {
    overlineEl.textContent = `NOW • MOMENT ${active.moment}`;
    titleEl.textContent = `Pray the ${active.title}`;
    messageEl.textContent = 'Take a moment. Pray together with Jesus Youth and your campus community.';
    countdownEl.innerHTML = `<span class="live-indicator"></span> Moment Active Now`;
    if (actionLabel) actionLabel.textContent = `PRAY ${active.title.toUpperCase()}`;
    if (actionBtn) {
      actionBtn.onclick = () => openDecadePrayerModal(active.decade);
    }
    return;
  }

  // State C: Next upcoming moment
  if (next) {
    const [h, m] = next.timeStr.split(':').map(Number);
    const targetDate = new Date(now);
    targetDate.setHours(h, m, 0, 0);
    const diffMs = targetDate - now;
    const diffSec = Math.max(0, Math.floor(diffMs / 1000));
    const hours = Math.floor(diffSec / 3600);
    const mins = Math.floor((diffSec % 3600) / 60);
    const secs = diffSec % 60;

    overlineEl.textContent = `NEXT • MOMENT ${next.moment}`;
    titleEl.textContent = `Pray the ${next.title} · ${next.label}`;
    messageEl.textContent = 'Pause. Pray. Continue the journey.';
    countdownEl.innerHTML = `Starts in <strong>${hours > 0 ? hours + 'h ' : ''}${mins}m ${secs}s</strong>`;
    
    // Find next unprayed decade
    const nextUnprayed = [1,2,3,4,5].find(n => !appState.prayedDecades.includes(n)) || next.decade;
    if (actionLabel) actionLabel.textContent = `PRAY DECADE 0${nextUnprayed}`;
    if (actionBtn) {
      actionBtn.onclick = () => openDecadePrayerModal(nextUnprayed);
    }
    return;
  }

  // State D: Day ended
  overlineEl.textContent = 'YOUR JOURNEY';
  titleEl.textContent = `${count} / 5 Moments Prayed`;
  messageEl.textContent = 'You don\'t need to stop your whole day for prayer. Give God five moments within it.';
  countdownEl.innerHTML = 'College day complete';
  const remaining = [1,2,3,4,5].find(n => !appState.prayedDecades.includes(n));
  if (remaining) {
    if (actionLabel) actionLabel.textContent = `PRAY REMAINING (DECADE ${remaining})`;
    if (actionBtn) actionBtn.onclick = () => openDecadePrayerModal(remaining);
  } else {
    if (actionLabel) actionLabel.textContent = 'REVIEW TODAY\'S ROSARY';
    if (actionBtn) actionBtn.onclick = () => window.scrollTo({ top: document.getElementById('journey-timeline').offsetTop - 100, behavior: 'smooth' });
  }
}

function renderFiveBeadMeters() {
  const count = appState.prayedDecades.length;
  
  // Hero meter
  const heroDots = document.querySelectorAll('.hero-meter-dots .meter-dot');
  heroDots.forEach((dot, index) => {
    dot.classList.remove('filled', 'current');
    if (appState.prayedDecades.includes(index + 1)) {
      dot.classList.add('filled');
    } else if (index + 1 === count + 1 && count < 5) {
      dot.classList.add('current');
    }
  });

  const heroLabel = document.getElementById('hero-meter-label');
  if (heroLabel) heroLabel.textContent = `${count} / 5 Moments`;

  // Navbar live pill
  const navPill = document.getElementById('nav-live-text');
  if (navPill) {
    if (count >= 5) {
      navPill.textContent = 'Journey Complete (5/5)';
    } else {
      navPill.textContent = `Moment ${count + 1} of 5`;
    }
  }
}

function renderTimelineHighlight(active) {
  const rows = document.querySelectorAll('.timeline-slot');
  rows.forEach((row, idx) => {
    const slot = appState.schedule[idx];
    row.classList.remove('current-slot');
    if (active && active.id === slot.id) {
      row.classList.add('current-slot');
    }
  });

  const cards = document.querySelectorAll('.journey-step-card');
  cards.forEach((card, idx) => {
    const decadeNum = idx + 1;
    card.classList.remove('completed');
    if (appState.prayedDecades.includes(decadeNum)) {
      card.classList.add('completed');
    }
  });
}

// ==========================================
// 5. GUIDED DECADE PRAYER MODAL
// ==========================================

function openDecadePrayerModal(decadeNum) {
  appState.activePrayingDecade = decadeNum;
  appState.currentBeadCount = 0;

  const modal = document.getElementById('prayer-modal');
  const title = document.getElementById('modal-decade-title');
  const mysteryName = document.getElementById('modal-mystery-name');
  const scripture = document.getElementById('modal-scripture');
  const fruit = document.getElementById('modal-fruit');

  const currentSet = MYSTERIES_DATA[appState.activeMysterySet];
  const decadeData = currentSet.decades[decadeNum - 1];

  if (title) title.textContent = `Moment 0${decadeNum} — Decade ${decadeNum}`;
  if (mysteryName) mysteryName.textContent = decadeData.title;
  if (scripture) scripture.textContent = decadeData.verse;
  if (fruit) fruit.textContent = `Fruit of the Mystery: ${decadeData.fruit}`;

  renderPrayerBeadsRing();

  if (modal) modal.classList.add('active');
  playPrayerChime();
}

function closePrayerModal() {
  const modal = document.getElementById('prayer-modal');
  if (modal) modal.classList.remove('active');
}

function renderPrayerBeadsRing() {
  const container = document.getElementById('modal-beads-container');
  if (!container) return;
  container.innerHTML = '';

  for (let i = 1; i <= 10; i++) {
    const bead = document.createElement('button');
    bead.className = `decade-bead ${i <= appState.currentBeadCount ? 'prayed' : ''}`;
    bead.setAttribute('aria-label', `Hail Mary bead ${i}`);
    bead.textContent = i;
    bead.onclick = () => {
      appState.currentBeadCount = i;
      playPrayerChime();
      renderPrayerBeadsRing();
      if (appState.currentBeadCount === 10) {
        showToast('Decade 10/10 Hail Marys completed! Finish with Glory Be.');
      }
    };
    container.appendChild(bead);
  }

  const beadCounter = document.getElementById('modal-bead-counter');
  if (beadCounter) beadCounter.textContent = `${appState.currentBeadCount} / 10 Hail Marys`;
}

function completeActiveDecade() {
  const d = appState.activePrayingDecade;
  if (!appState.prayedDecades.includes(d)) {
    appState.prayedDecades.push(d);
    appState.prayedDecades.sort((a,b) => a - b);
    localStorage.setItem('bead5_prayed_today', JSON.stringify(appState.prayedDecades));
  }
  closePrayerModal();
  updateLiveEngine();
  playPrayerChime();

  if (appState.prayedDecades.length === 5) {
    showToast('Praise God! You completed the five moments today!');
    openCompletionModal();
  } else {
    showToast(`Moment 0${d} marked complete! Continue the journey.`);
  }
}

// ==========================================
// 6. JOURNEY COMPLETE CELEBRATION (Section 20)
// ==========================================

function openCompletionModal() {
  const modal = document.getElementById('completion-modal');
  if (modal) modal.classList.add('active');
}

function closeCompletionModal() {
  const modal = document.getElementById('completion-modal');
  if (modal) modal.classList.remove('active');
}

function openCertificateModal() {
  const modal = document.getElementById('certificate-modal');
  if (modal) modal.classList.add('active');
}

function closeCertificateModal() {
  const modal = document.getElementById('certificate-modal');
  if (modal) modal.classList.remove('active');
}

// ==========================================
// 7. TIME SIMULATION / DEMONSTRATION CONTROLS
// ==========================================

function setSimulationTime(momentId) {
  const buttons = document.querySelectorAll('.sim-btn');
  buttons.forEach(b => b.classList.remove('active'));

  if (momentId === 'real') {
    appState.currentSimulatedTime = null;
    showToast('Reset to real campus clock');
  } else if (momentId === 'done') {
    appState.prayedDecades = [1, 2, 3, 4, 5];
    localStorage.setItem('bead5_prayed_today', JSON.stringify(appState.prayedDecades));
    showToast('All 5 moments marked complete');
  } else if (momentId === 'reset') {
    appState.prayedDecades = [];
    localStorage.setItem('bead5_prayed_today', JSON.stringify([]));
    showToast('Progress reset to 0 / 5');
  } else {
    const slot = appState.schedule.find(s => s.id === Number(momentId));
    if (slot) {
      const now = new Date();
      const [h, m] = slot.timeStr.split(':').map(Number);
      now.setHours(h, m + 2, 0, 0); // 2 mins inside the active window
      appState.currentSimulatedTime = now.getTime();
      showToast(`Simulating ${slot.label} (Moment 0${slot.id})`);
    }
  }

  const activeBtn = document.querySelector(`[data-sim="${momentId}"]`);
  if (activeBtn) activeBtn.classList.add('active');

  updateLiveEngine();
}

// ==========================================
// 8. MULTI-CHANNEL ASSET STUDIO (Sections 21-23, 30)
// ==========================================

function initAssetStudio() {
  const filterChips = document.querySelectorAll('.studio-chip');
  const cards = document.querySelectorAll('.creative-card');

  filterChips.forEach(chip => {
    chip.addEventListener('click', () => {
      filterChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      const filter = chip.getAttribute('data-filter');

      cards.forEach(card => {
        if (filter === 'all' || card.getAttribute('data-category') === filter) {
          card.style.display = 'flex';
        } else {
          card.style.display = 'none';
        }
      });
    });
  });
}

function downloadCreativeSVG(elementId, filename) {
  const el = document.getElementById(elementId);
  if (!el) return;

  const width = el.offsetWidth;
  const height = el.offsetHeight;
  const clone = el.cloneNode(true);
  
  // Create SVG wrapper
  const svgData = `
    <svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
      <foreignObject width="100%" height="100%">
        <div xmlns="http://www.w3.org/1999/xhtml" style="font-family: 'Plus Jakarta Sans', sans-serif;">
          ${clone.outerHTML}
        </div>
      </foreignObject>
    </svg>
  `;

  const blob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${filename}.svg`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast(`Downloaded ${filename}.svg`);
}

function shareOnWhatsApp(text) {
  const campaignMsg = encodeURIComponent(
    `*BEAD5 — Five Moments. One Journey.*\n` +
    `ROSARY MONTH CAMPAIGN\n` +
    `_Jesus Youth — Pazhassiraja College_\n\n` +
    `"You don't need to stop your whole day for prayer. Give God five moments within it."\n\n` +
    `Join our campus Rosary journey: https://bead5jyprc.web.app`
  );
  window.open(`https://api.whatsapp.com/send?text=${campaignMsg}`, '_blank');
}

// ==========================================
// 9. UTILITIES & TOASTS
// ==========================================

function showToast(message) {
  let toast = document.getElementById('toast-msg');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast-msg';
    toast.className = 'toast-msg';
    document.body.appendChild(toast);
  }
  toast.innerHTML = `<span>●</span> ${message}`;
  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 3200);
}

function copyColorHex(hex, name) {
  navigator.clipboard.writeText(hex).then(() => {
    showToast(`Copied ${name} (${hex}) to clipboard!`);
  }).catch(() => {
    showToast(`Palette: ${name} (${hex})`);
  });
}

// ==========================================
// 10. BOOTSTRAP ON DOM READY
// ==========================================

document.addEventListener('DOMContentLoaded', () => {
  initIntroAnimation();
  initAssetStudio();

  // Setup mystery chip listeners
  const mysteryChips = document.querySelectorAll('.mystery-chip');
  mysteryChips.forEach(chip => {
    chip.addEventListener('click', () => {
      mysteryChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      appState.activeMysterySet = chip.getAttribute('data-mystery');
      renderJourneyTimeline();
      showToast(`Selected ${MYSTERIES_DATA[appState.activeMysterySet].name}`);
    });
  });

  // Setup simulation buttons
  const simButtons = document.querySelectorAll('.sim-btn');
  simButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const mode = btn.getAttribute('data-sim');
      setSimulationTime(mode);
    });
  });

  // Setup certificate name live updating
  const certInput = document.getElementById('cert-student-name-input');
  if (certInput) {
    certInput.addEventListener('input', (e) => {
      const val = e.target.value.trim() || 'Mary student';
      const disp = document.getElementById('cert-student-name-display');
      if (disp) disp.textContent = val;
    });
  }

  // Ticking live engine every second
  updateLiveEngine();
  setInterval(updateLiveEngine, 1000);
});

function renderJourneyTimeline() {
  const currentSet = MYSTERIES_DATA[appState.activeMysterySet];
  const list = document.querySelectorAll('.journey-step-card');
  list.forEach((card, idx) => {
    const decadeData = currentSet.decades[idx];
    const titleEl = card.querySelector('.step-title');
    const scriptureEl = card.querySelector('.step-scripture');
    if (titleEl) titleEl.textContent = `${decadeData.title}`;
    if (scriptureEl) scriptureEl.textContent = `${decadeData.verse} • Fruit: ${decadeData.fruit}`;
  });
}
