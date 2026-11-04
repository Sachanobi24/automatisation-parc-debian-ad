import Link from 'next/link'
import FadeIn from '@/components/FadeIn'
import { config } from '@/data/config'

const label = {
  fontFamily: 'var(--font-display)',
  fontSize: '0.75rem',
  color: 'var(--primary)',
  letterSpacing: '0.1em',
  textTransform: 'uppercase' as const,
  margin: '1.5rem 0 0.75rem',
}

// Lien interne (page du site) ou externe / fichier (nouvel onglet)
function ProjetLink({ titre, href }: { titre: string; href: string }) {
  const style = { fontSize: '0.65rem', padding: '0.4rem 0.75rem' }
  const interne = href.startsWith('/') && !/\.(png|jpe?g|pdf)$/i.test(href)
  return interne ? (
    <Link href={href} className="btn btn-outline" style={style}>{titre} →</Link>
  ) : (
    <a href={href} target="_blank" rel="noopener noreferrer" className="btn btn-outline" style={style}>{titre} ↗</a>
  )
}

export default function CompetencesPage() {
  const { competencesDetail } = config

  return (
    <>
      <div className="page-hero">
        <div className="container">
          <p className="page-hero-label">Compétences</p>
          <h1>Mes compétences<br />en détail</h1>
          <p>Pour chaque domaine : les outils que j’ai utilisés, ce que j’en ai fait, et les projets associés.</p>
        </div>
      </div>

      <section className="section">
        <div className="container" style={{ maxWidth: '900px' }}>
          <Link href="/#competences" className="btn btn-outline" style={{ fontSize: '0.65rem', padding: '0.4rem 0.75rem' }}>
            ← Retour à l’accueil
          </Link>

          {/* Sommaire */}
          <div className="project-tags" style={{ margin: '2rem 0 3rem' }}>
            {competencesDetail.map((c) => (
              <a key={c.id} href={`#${c.id}`} className="tech-badge" style={{ textDecoration: 'none' }}>
                {c.emoji} {c.titre}
              </a>
            ))}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            {competencesDetail.map((c, i) => (
              <FadeIn key={c.id} delay={i * 40}>
                <article id={c.id} className="card" style={{ padding: '1.75rem', scrollMarginTop: '100px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.9rem', marginBottom: '0.75rem' }}>
                    <span style={{ fontSize: '1.8rem' }}>{c.emoji}</span>
                    <h2 style={{ fontSize: '1.15rem' }}>{c.titre}</h2>
                  </div>
                  <p style={{ color: 'var(--text-muted)', fontSize: '0.95rem' }}>{c.resume}</p>

                  <h3 style={label}>Outils & technologies</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                    {c.outils.map((o) => (
                      <div key={o.nom} style={{ borderLeft: '2px solid var(--primary)', paddingLeft: '0.9rem' }}>
                        <strong style={{ fontSize: '0.9rem' }}>{o.nom}</strong>
                        <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>{o.usage}</p>
                      </div>
                    ))}
                  </div>

                  {c.projets.length > 0 && (
                    <>
                      <h3 style={label}>Projets associés</h3>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.6rem' }}>
                        {c.projets.map((p) => (
                          <ProjetLink key={p.titre} titre={p.titre} href={p.href} />
                        ))}
                      </div>
                    </>
                  )}
                </article>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>
    </>
  )
}
