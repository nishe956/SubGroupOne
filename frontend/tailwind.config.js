/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a8a',
        },
        // Accent de l'espace d'administration. Le reste du site reste sur
        // `primary` : cet orange n'habille que le back-office.
        accent: {
          50: '#fff5ef',
          100: '#ffe8db',
          200: '#fecdb2',
          300: '#fdaa80',
          400: '#fb7f4b',
          500: '#f26b21',
          600: '#e05513',
          700: '#b94012',
          800: '#933516',
          900: '#772e15',
        },
        gold: {
          500: '#f59e0b',
          600: '#d97706',
        },
      },
      boxShadow: {
        // Ombre des cartes du back-office : très basse opacité, diffusion large.
        card: '0 1px 2px rgba(16,24,40,0.04), 0 10px 30px -18px rgba(16,24,40,0.25)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
