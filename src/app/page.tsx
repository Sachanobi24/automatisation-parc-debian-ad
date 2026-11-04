import Link from 'next/link'
import FadeIn from '@/components/FadeIn'
import SkillBar from '@/components/SkillBar'
import { config } from '@/data/config'

export default function HomePage() {
  const { identity, apropos, competences } = config

  return (
    <>
      {/* ── HERO ── */}
      <section className="home-hero" id="accueil">
        <div className="container">
          <div className="hero-content">
            <div className="hero-status" role="status">
              {identity.statut}
            </div>

            <h1 className="hero-name">
              {identity.prenom}<br />{identity.nom}
            </h1>

            <p className="hero-title">
              {identity.poste}<span className="cursor" aria-hidden="true" />
            </p>

            <p className="hero-desc">{identity.description}</p>

            <div className="hero-actions">
              <Link href="/projets" className="btn btn-primary">Voir mes projets</Link>
              <Link href="/contact" className="btn btn-outline">Me contacter</Link>
            </div>

            <div className="hero-stats">
              {apropos.stats.map((s) => (
                <div key={s.label} className="hero-stat">
                  <span className="hero-stat-number">{s.nombre}</span>
                  <span className="hero-stat-label">{s.label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Réseau décoratif */}
          <svg className="hero-visual" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <circle cx="200" cy="200" r="12" fill="none" stroke="#00d4ff" strokeWidth="2" />
            <circle cx="80" cy="100" r="8" fill="none" stroke="#00d4ff" strokeWidth="1.5" />
            <circle cx="320" cy="80" r="8" fill="none" stroke="#00d4ff" strokeWidth="1.5" />
            <circle cx="350" cy="280" r="8" fill="none" stroke="#00d4ff" strokeWidth="1.5" />
            <circle cx="50" cy="300" r="8" fill="none" stroke="#00d4ff" strokeWidth="1.5" />
            <circle cx="200" cy="360" r="6" fill="none" stroke="#7fff00" strokeWidth="1" />
            <circle cx="150" cy="60" r="6" fill="none" stroke="#7fff00" strokeWidth="1" />
            <circle cx="300" cy="180" r="6" fill="none" stroke="#7fff00" strokeWidth="1" />
            <line x1="200" y1="200" x2="80" y2="100" stroke="#00d4ff" strokeWidth="1" opacity="0.5" />
            <line x1="200" y1="200" x2="320" y2="80" stroke="#00d4ff" strokeWidth="1" opacity="0.5" />
            <line x1="200" y1="200" x2="350" y2="280" stroke="#00d4ff" strokeWidth="1" opacity="0.5" />
            <line x1="200" y1="200" x2="50" y2="300" stroke="#00d4ff" strokeWidth="1" opacity="0.5" />
            <line x1="200" y1="200" x2="200" y2="360" stroke="#7fff00" strokeWidth="1" opacity="0.4" />
            <line x1="80" y1="100" x2="150" y2="60" stroke="#00d4ff" strokeWidth="0.5" opacity="0.3" />
            <line x1="320" y1="80" x2="300" y2="180" stroke="#00d4ff" strokeWidth="0.5" opacity="0.3" />
            <line x1="350" y1="280" x2="300" y2="180" stroke="#7fff00" strokeWidth="0.5" opacity="0.3" />
            <line x1="80" y1="100" x2="50" y2="300" stroke="#00d4ff" strokeWidth="0.5" opacity="0.2" />
          </svg>
        </div>
      </section>

      {/* ── À PROPOS ── */}
      <section className="section" id="a-propos">
        <div className="container">
          <p className="page-hero-label" aria-hidden="true">01 / À propos</p>

          <div className="about-grid" style={{ marginTop: '2rem' }}>
            {/* Avatar */}
            <FadeIn className="about-avatar">
              <img
                src="/Photo-Mathys.jpg"
                alt="Photo de profil"
                style={{
                  width: '160px',
                  height: '160px',
                  objectFit: 'cover',
                  borderRadius: '8px',
                  border: '2px solid var(--border)',
                }}
              />
              <div className="avatar-name">
                {identity.prenom} {identity.nom}<br />
                <span style={{ color: 'var(--text-muted)', fontSize: '0.8rem', fontFamily: 'var(--font-body)' }}>
                  {identity.ville}
                </span>
              </div>
              <span className="avatar-badge">BTS SIO — SISR</span>
            </FadeIn>

            {/* Infos */}
            <FadeIn>
              <h2 style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>À propos de moi</h2>
              <p className="subtitle" style={{ color: 'var(--text-muted)', marginBottom: '1.5rem' }}>
                {identity.poste}
              </p>

              <div className="about-content">
                {apropos.paragraphes.map((p, i) => (
                  <p key={i} style={{ marginBottom: '1rem', color: 'var(--text-muted)' }}
                    dangerouslySetInnerHTML={{ __html: p }} />
                ))}
              </div>

              <dl className="info-list">
                {apropos.infos.map((info) => (
                  <div key={info.label} className="info-item">
                    <dt>{info.label}</dt>
                    <dd>{info.valeur}</dd>
                  </div>
                ))}
                {identity.ville && (
                  <div className="info-item">
                    <dt>Localisation</dt>
                    <dd>{identity.ville}</dd>
                  </div>
                )}
                {identity.email && (
                  <div className="info-item">
                    <dt>Email</dt>
                    <dd><a href={`mailto:${identity.email}`}>{identity.email}</a></dd>
                  </div>
                )}
              </dl>

              <div style={{ marginTop: '2rem', display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
                {identity.cvUrl && (
                  <a href="/cv" className="btn btn-primary">
                    Voir mon CV
                  </a>
                )}
                <Link href="/contact" className="btn btn-outline">Me contacter</Link>
              </div>
            </FadeIn>
          </div>

          {/* Compétences */}
          <div id="competences" style={{ marginTop: '5rem', scrollMarginTop: '100px' }}>
            <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', marginBottom: '1.5rem' }}>
              <h3 className="section-title" style={{ fontSize: '1.3rem', marginBottom: 0 }}>Compétences techniques</h3>
              <Link href="/competences" className="btn btn-outline" style={{ fontSize: '0.7rem' }}>
                Détail de mes compétences →
              </Link>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '3rem' }}>
              {competences.map((cat) => (
                <div key={cat.categorie}>
                  <h4 style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: '0.8rem',
                    color: 'var(--primary)',
                    letterSpacing: '0.1em',
                    textTransform: 'uppercase',
                    marginBottom: '1.5rem',
                  }}>
                    {cat.categorie}
                  </h4>
                  {cat.items.map((item) => (
                    <SkillBar key={item.nom} nom={item.nom} niveau={item.niveau} detail={item.detail} />
                  ))}
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>
    </>
  )
}
