import React from 'react'

// Petits composants partagés par les pages de détail des projets

export const muted = { color: 'var(--text-muted)', fontSize: '0.95rem' }

export function Sub({ children }: { children: React.ReactNode }) {
  return (
    <h3
      style={{
        fontFamily: 'var(--font-display)',
        fontSize: '0.85rem',
        color: 'var(--primary)',
        letterSpacing: '0.1em',
        textTransform: 'uppercase',
        margin: '2rem 0 1rem',
      }}
    >
      {children}
    </h3>
  )
}

export function Table({ head, rows }: { head: string[]; rows: string[][] }) {
  const cell = { padding: '0.6rem 0.9rem', textAlign: 'left' as const, fontSize: '0.85rem', borderBottom: '1px solid var(--border)' }
  return (
    <div style={{ overflowX: 'auto', margin: '1rem 0' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', background: 'var(--bg-card)', border: '1px solid var(--border)' }}>
        <thead>
          <tr>
            {head.map((h) => (
              <th key={h} style={{ ...cell, color: 'var(--primary)', fontFamily: 'var(--font-display)', fontWeight: 400, fontSize: '0.75rem', letterSpacing: '0.08em', textTransform: 'uppercase' }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i}>
              {r.map((c, j) => (
                <td key={j} style={{ ...cell, color: j === 0 ? 'var(--text-main)' : 'var(--text-muted)' }}>{c}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export function Figure({ src, alt, caption }: { src: string; alt: string; caption: string }) {
  return (
    <figure style={{ margin: '1.5rem 0' }}>
      <img src={src} alt={alt} style={{ width: '100%', height: 'auto', display: 'block', border: '1px solid var(--border)', borderRadius: 'var(--radius)' }} />
      <figcaption style={{ fontSize: '0.75rem', color: 'var(--text-dim)', marginTop: '0.5rem', fontFamily: 'var(--font-display)' }}>
        {caption}
      </figcaption>
    </figure>
  )
}

export function Bullets({ items }: { items: string[] }) {
  return (
    <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '0.5rem', margin: '1rem 0' }}>
      {items.map((it, i) => (
        <li key={i} style={{ ...muted, paddingLeft: '1.25rem', position: 'relative' }}>
          <span style={{ position: 'absolute', left: 0, color: 'var(--primary)' }}>›</span>
          {it}
        </li>
      ))}
    </ul>
  )
}

export function Code({ children }: { children: string }) {
  return (
    <pre style={{ background: 'var(--bg-card)', border: '1px solid var(--border)', padding: '0.9rem 1rem', overflowX: 'auto', fontSize: '0.8rem', color: 'var(--primary)', margin: '1rem 0' }}>
      <code>{children}</code>
    </pre>
  )
}
