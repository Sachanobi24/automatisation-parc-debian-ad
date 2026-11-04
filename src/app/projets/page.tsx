'use client'
import FadeIn from '@/components/FadeIn'
import Link from 'next/link'
import { config } from '@/data/config'

export default function ProjetsPage() {
  const { projets } = config

  return (
    <>
      <div className="page-hero">
        <div className="container">
          <p className="page-hero-label">06 / Portfolio</p>
          <h1>Projets<br />Réalisés</h1>
          <p>Mes projets techniques en systèmes, réseaux et infrastructure.</p>
        </div>
      </div>

      <section className="section">
        <div className="container">
          <div className="projects-grid">
            {projets.map((projet, i) => (
              <FadeIn key={i} delay={i * 80}>
                <article className="project-card">

                  {projet.image && (
                    <div style={{ width: '100%', height: '180px', overflow: 'hidden', borderBottom: '1px solid var(--border)', position: 'relative' }}>
                      <img
                        src={projet.image}
                        alt={`Aperçu ${projet.titre}`}
                        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block', transition: 'transform 0.4s ease' }}
                        onMouseEnter={(e) => { e.currentTarget.style.transform = 'scale(1.05)' }}
                        onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)' }}
                      />
                      {(() => {
                        const overlayStyle = {
                          position: 'absolute' as const, inset: 0,
                          background: 'rgba(3,13,26,0.6)',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          opacity: 0, transition: 'opacity 0.3s ease',
                          fontFamily: 'var(--font-display)', fontSize: '0.75rem',
                          color: 'var(--primary)', letterSpacing: '0.1em', textTransform: 'uppercase' as const,
                        }
                        const show = (e: React.MouseEvent<HTMLElement>) => { e.currentTarget.style.opacity = '1' }
                        const hide = (e: React.MouseEvent<HTMLElement>) => { e.currentTarget.style.opacity = '0' }
                        const page = (projet as { page?: string }).page
                        if (page) {
                          return (
                            <Link href={page} style={overlayStyle} onMouseEnter={show} onMouseLeave={hide}>
                              Voir le détail →
                            </Link>
                          )
                        }
                        if (projet.url) {
                          return (
                            <a href={projet.url} target="_blank" rel="noopener noreferrer"
                              style={overlayStyle} onMouseEnter={show} onMouseLeave={hide}>
                              Visiter le site →
                            </a>
                          )
                        }
                        return null
                      })()}
                    </div>
                  )}

                  <div className="project-header">
                    <div className="project-icon">{projet.emoji}</div>
                    <div>
                      <h3 style={{ fontSize: '1rem' }}>{projet.titre}</h3>
                      <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontFamily: 'var(--font-display)' }}>
                        {projet.type}
                      </p>
                    </div>
                  </div>

                  <div className="project-body">
                    <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>{projet.description}</p>
                    <div className="project-tags">
                      {projet.tags.map((tag) => (
                        <span key={tag} className="tech-badge">{tag}</span>
                      ))}
                    </div>
                    {(projet as { page?: string }).page && (
                      <div style={{ marginTop: '1.25rem' }}>
                        <Link href={(projet as { page?: string }).page as string}
                          className="btn btn-outline" style={{ fontSize: '0.65rem', padding: '0.4rem 0.75rem' }}>
                          Voir le détail du projet
                        </Link>
                      </div>
                    )}
                    {!(projet as { page?: string }).page && projet.url && (
                      <div style={{ marginTop: '1.25rem' }}>
                        <a href={projet.url} target="_blank" rel="noopener noreferrer"
                          className="btn btn-outline" style={{ fontSize: '0.65rem', padding: '0.4rem 0.75rem' }}>
                          Voir le projet
                        </a>
                      </div>
                    )}
                  </div>

                </article>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>
    </>
  )
}
