/**
 * Chronos Weather — Time & weather with sleek animations
 * Uses Open-Meteo API (no API key required)
 */

// --- Time
const dateEl = document.getElementById('date');
const ampmEl = document.getElementById('ampm');
const digitIds = ['hour-tens', 'hour-ones', 'min-tens', 'min-ones', 'sec-tens', 'sec-ones'];
const digitEls = digitIds.map(id => document.getElementById(id));

const optionsDate = { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' };
const optionsTime = { hour12: true, hour: '2-digit', minute: '2-digit', second: '2-digit' };

let lastTime = '';

function formatTwo(n) {
  return String(n).padStart(2, '0');
}

function updateDate() {
  const now = new Date();
  dateEl.textContent = now.toLocaleDateString(undefined, optionsDate);
}

function getDigits(now) {
  const h = now.getHours();
  const m = now.getMinutes();
  const s = now.getSeconds();
  const hour12 = h % 12 || 12;
  const tens = (n) => Math.floor(n / 10);
  const ones = (n) => n % 10;
  return [
    tens(hour12),
    ones(hour12),
    tens(m),
    ones(m),
    tens(s),
    ones(s),
  ];
}

function setAmpm(now) {
  const segmenter = new Intl.DateTimeFormat(undefined, { hour12: true, hour: 'numeric' });
  const parts = segmenter.formatToParts(now);
  const ampm = parts.find(p => p.type === 'dayPeriod')?.value ?? (now.getHours() >= 12 ? 'PM' : 'AM');
  ampmEl.textContent = ampm;
}

function updateClock() {
  const now = new Date();
  const digits = getDigits(now);

  digitEls.forEach((el, i) => {
    const next = String(digits[i]);
    if (el.textContent !== next) {
      el.textContent = next;
      el.classList.add('flip');
      el.addEventListener('animationend', () => el.classList.remove('flip'), { once: true });
    }
  });

  setAmpm(now);
  lastTime = now.toTimeString();
}

// --- Weather (Open-Meteo)
const locationNameEl = document.getElementById('location-name');
const tempEl = document.getElementById('temp');
const weatherDescEl = document.getElementById('weather-desc');
const humidityEl = document.getElementById('humidity');
const windEl = document.getElementById('wind');
const weatherIconEl = document.getElementById('weather-icon');

const WEATHER_CODES = {
  0: { desc: 'Clear', icon: 'clear' },
  1: { desc: 'Mainly clear', icon: 'clear' },
  2: { desc: 'Partly cloudy', icon: 'partly-cloudy' },
  3: { desc: 'Overcast', icon: 'cloudy' },
  45: { desc: 'Foggy', icon: 'fog' },
  48: { desc: 'Depositing rime fog', icon: 'fog' },
  51: { desc: 'Light drizzle', icon: 'drizzle' },
  53: { desc: 'Drizzle', icon: 'drizzle' },
  55: { desc: 'Dense drizzle', icon: 'drizzle' },
  61: { desc: 'Slight rain', icon: 'rain' },
  63: { desc: 'Rain', icon: 'rain' },
  65: { desc: 'Heavy rain', icon: 'rain' },
  71: { desc: 'Slight snow', icon: 'snow' },
  73: { desc: 'Snow', icon: 'snow' },
  75: { desc: 'Heavy snow', icon: 'snow' },
  77: { desc: 'Snow grains', icon: 'snow' },
  80: { desc: 'Slight rain showers', icon: 'rain' },
  81: { desc: 'Rain showers', icon: 'rain' },
  82: { desc: 'Violent rain showers', icon: 'rain' },
  85: { desc: 'Slight snow showers', icon: 'snow' },
  86: { desc: 'Heavy snow showers', icon: 'snow' },
  95: { desc: 'Thunderstorm', icon: 'thunder' },
  96: { desc: 'Thunderstorm with hail', icon: 'thunder' },
};

function getWeatherIcon(name) {
  const icons = {
    clear: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="32" cy="32" r="16" fill="url(#sun)"/>
      <circle cx="32" cy="32" r="20" stroke="url(#sun)" stroke-width="2" opacity="0.5"/>
      <defs><linearGradient id="sun" x1="20" y1="20" x2="44" y2="44" gradientUnits="userSpaceOnUse">
        <stop stop-color="#ffd93d"/><stop offset="1" stop-color="#ff9a3d"/>
      </linearGradient></defs>
    </svg>`,
    'partly-cloudy': `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="28" cy="28" r="12" fill="url(#sun2)"/>
      <path d="M20 44a14 14 0 0 1 24-8 10 10 0 0 1 8 10 10 10 0 0 1-10 10H22a12 12 0 0 1-2-24Z" fill="rgba(255,255,255,0.9)"/>
      <defs><linearGradient id="sun2" x1="18" y1="18" x2="38" y2="38"><stop stop-color="#ffd93d"/><stop offset="1" stop-color="#ff9a3d"/></linearGradient></defs>
    </svg>`,
    cloudy: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M16 44a16 16 0 0 1 28-10 12 12 0 0 1 8 12 12 12 0 0 1-12 12H20a16 16 0 0 1-4-32Z" fill="rgba(255,255,255,0.85)"/>
    </svg>`,
    fog: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <ellipse cx="32" cy="40" rx="24" ry="6" fill="rgba(255,255,255,0.4)"/>
      <ellipse cx="32" cy="32" rx="28" ry="6" fill="rgba(255,255,255,0.3)"/>
      <ellipse cx="32" cy="24" rx="22" ry="6" fill="rgba(255,255,255,0.35)"/>
    </svg>`,
    drizzle: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M32 12v24M24 20v16M40 20v16M28 44l4 12M36 44l4 12M20 38l4 12" stroke="rgba(124,106,255,0.9)" stroke-width="2.5" stroke-linecap="round"/>
      <path d="M16 44a16 16 0 0 1 28-10 12 12 0 0 1 8 12 12 12 0 0 1-12 12H20a16 16 0 0 1-4-32Z" fill="rgba(255,255,255,0.6)"/>
    </svg>`,
    rain: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M16 44a16 16 0 0 1 28-10 12 12 0 0 1 8 12 12 12 0 0 1-12 12H20a16 16 0 0 1-4-32Z" fill="rgba(255,255,255,0.7)"/>
      <path d="M26 38v10M32 34v14M38 40v8M22 44v6M40 44v6" stroke="#7c6aff" stroke-width="2" stroke-linecap="round" opacity="0.9"/>
    </svg>`,
    snow: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M16 44a16 16 0 0 1 28-10 12 12 0 0 1 8 12 12 12 0 0 1-12 12H20a16 16 0 0 1-4-32Z" fill="rgba(255,255,255,0.8)"/>
      <path d="M32 28v8M28 32h8M30 30l4 4M34 30l-4 4" stroke="rgba(255,255,255,0.95)" stroke-width="1.5" stroke-linecap="round"/>
    </svg>`,
    thunder: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M16 44a16 16 0 0 1 28-10 12 12 0 0 1 8 12 12 12 0 0 1-12 12H20a16 16 0 0 1-4-32Z" fill="rgba(255,255,255,0.6)"/>
      <path d="M36 22L28 34h6l-4 14 14-18h-6l4-12z" fill="#ffd93d"/>
    </svg>`,
  };
  return icons[name] || icons.cloudy;
}

function getWeatherInfo(code) {
  return WEATHER_CODES[code] || WEATHER_CODES[3];
}

async function fetchWeather(lat, lon) {
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto`;
  const res = await fetch(url);
  if (!res.ok) throw new Error('Weather fetch failed');
  return res.json();
}

async function reverseGeocode(lat, lon) {
  try {
    const res = await fetch(
      `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`,
      { headers: { Accept: 'application/json' } }
    );
    const data = await res.json();
    const city = data.address?.city || data.address?.town || data.address?.village || data.address?.county || 'Unknown';
    return city;
  } catch {
    return `${lat.toFixed(1)}°, ${lon.toFixed(1)}°`;
  }
}

function renderWeather(data) {
  const cur = data.current;
  const info = getWeatherInfo(cur.weather_code);
  const temp = Math.round(cur.temperature_2m);
  const windKmh = Math.round(cur.wind_speed_10m);

  tempEl.textContent = temp;
  tempEl.classList.add('updated');
  tempEl.addEventListener('animationend', () => tempEl.classList.remove('updated'), { once: true });

  weatherDescEl.textContent = info.desc;
  humidityEl.textContent = `${cur.relative_humidity_2m}% humidity`;
  windEl.textContent = `${windKmh} km/h wind`;
  weatherIconEl.innerHTML = getWeatherIcon(info.icon);
}

async function loadWeather() {
  return new Promise((resolve) => {
    if (!navigator.geolocation) {
      locationNameEl.textContent = 'Geolocation not available';
      fetchWeather(52.52, 13.41).then(renderWeather).catch(() => {
        weatherDescEl.textContent = 'Weather unavailable';
      }).finally(resolve);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const { latitude, longitude } = pos.coords;
        try {
          const [weatherData, city] = await Promise.all([
            fetchWeather(latitude, longitude),
            reverseGeocode(latitude, longitude),
          ]);
          locationNameEl.textContent = city;
          renderWeather(weatherData);
        } catch (e) {
          locationNameEl.textContent = 'Location OK';
          weatherDescEl.textContent = 'Weather unavailable';
        }
        resolve();
      },
      () => {
        locationNameEl.textContent = 'Location denied — using Berlin';
        fetchWeather(52.52, 13.41).then(renderWeather).catch(() => {
          weatherDescEl.textContent = 'Weather unavailable';
        }).finally(resolve);
      },
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 }
    );
  });
}

// --- Init
updateDate();
updateClock();
setInterval(updateClock, 1000);
setInterval(updateDate, 60000);

loadWeather();
setInterval(loadWeather, 10 * 60 * 1000); // refresh weather every 10 min
