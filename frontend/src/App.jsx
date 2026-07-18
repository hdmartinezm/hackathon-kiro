import { useState, useEffect } from 'react'

function App() {
  const [apiStatus, setApiStatus] = useState('checking...')

  useEffect(() => {
    fetch('/api/health')
      .then(res => res.json())
      .then(data => setApiStatus(data.status))
      .catch(() => setApiStatus('offline'))
  }, [])

  return (
    <div style={{ padding: '2rem', fontFamily: 'system-ui' }}>
      <h1>Hackathon App</h1>
      <p>API Status: <strong>{apiStatus}</strong></p>
      <p style={{ color: '#666', marginTop: '2rem' }}>
        Edita <code>src/App.jsx</code> para comenzar
      </p>
    </div>
  )
}

export default App
