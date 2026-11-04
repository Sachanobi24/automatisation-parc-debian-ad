'use client'
import { useEffect, useRef } from 'react'
import Link from 'next/link'

export default function SkillBar({ nom, niveau, detail }: { nom: string; niveau: number; detail?: string }) {
  const fillRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const el = fillRef.current
    if (!el) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add('animated')
          observer.unobserve(el)
        }
      },
      { threshold: 0.5 }
    )
    observer.observe(el)
    return () => observer.disconnect()
  }, [])

  return (
    <div className="skill-bar">
      <div className="skill-bar-header">
        {detail ? (
          <Link href={`/competences#${detail}`} title="Voir le détail" style={{ color: 'inherit', borderBottom: '1px dotted var(--primary)' }}>
            {nom} →
          </Link>
        ) : (
          <span>{nom}</span>
        )}
        <span>{niveau}%</span>
      </div>
      <div className="skill-bar-track">
        <div
          ref={fillRef}
          className="skill-bar-fill"
          style={{ width: `${niveau}%` }}
        />
      </div>
    </div>
  )
}
