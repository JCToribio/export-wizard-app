import axios from 'axios'

// Edit this baseURL to match your ColdFusion server base (example: http://localhost:8500/export-wizard/server/cf)
const api = axios.create({ baseURL: 'http://localhost:8500/export-wizard/server/cf' })

export default api
