import { createApp } from 'vue'
import App from './App.vue'
import tilt from './directives/tilt.js'
import './styles/global.css'

createApp(App).directive('tilt', tilt).mount('#app')
