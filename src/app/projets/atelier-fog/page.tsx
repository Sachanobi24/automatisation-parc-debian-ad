import Link from 'next/link'
import FadeIn from '@/components/FadeIn'
import { muted, Sub, Table, Figure, Bullets, Code } from '@/components/ProjetDoc'

const competences = ['FOG', 'Debian 13', 'PXE / iPXE', 'DHCP', 'Clonage d’images', 'Windows 11', 'Dépannage réseau']

export default function AtelierFogPage() {
  return (
    <>
      <div className="page-hero">
        <div className="container">
          <p className="page-hero-label">Atelier / Déploiement</p>
          <h1>Atelier FOG</h1>
          <p>Capture et déploiement d’images système sur un parc de postes avec le serveur FOG.</p>
        </div>
      </div>

      <section className="section">
        <div className="container" style={{ maxWidth: '900px' }}>
          <Link href="/projets" className="btn btn-outline" style={{ fontSize: '0.65rem', padding: '0.4rem 0.75rem' }}>
            ← Retour aux projets
          </Link>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '2.5rem' }}>Objectif</h2>
            <p style={muted}>
              FOG est une solution libre de déploiement d’images : on capture le système d’un poste
              « maître », puis on le déploie sur d’autres postes par le réseau (démarrage PXE), sans
              installer chaque machine à la main. L’atelier consistait à monter cette chaîne de bout en bout.
            </p>
          </FadeIn>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Plateforme</h2>
            <Bullets
              items={[
                'Un serveur Debian 13 sur lequel FOG est installé, avec une adresse IP obtenue en DHCP.',
                'Trois PC, dont un poste maître avec un système d’exploitation de référence (Windows 11 ou Debian 13) dont on capture l’image.',
                'Un switch qui relie les PC et le serveur dans un réseau interne en étoile.',
              ]}
            />
            <Figure
              src="/projets/fog-atelier.svg"
              alt="Schéma en étoile : un switch relie le serveur FOG, le PC maître et deux PC cibles"
              caption="Topologie de l’atelier et étapes : capture, stockage, déploiement."
            />
          </FadeIn>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Problèmes rencontrés et solutions</h2>

            <Sub>FOG installé sans le mode DHCP</Sub>
            <p style={muted}>
              Si FOG n’est pas installé avec la configuration DHCP prévue, le plus fiable est de
              réinstaller entièrement le serveur Debian (sauf si d’autres services y sont déjà installés).
              Leçon retenue : fixer ce choix dès le début de l’installation.
            </p>

            <Sub>Échec de la capture du poste Windows</Sub>
            <p style={muted}>
              La cause était des adresses IP qui ne correspondaient plus au réseau local. Elles sont à
              corriger à plusieurs endroits :
            </p>
            <Table
              head={['Où', 'Quoi']}
              rows={[
                ['Ligne de commande', 'Le fichier de configuration principale de FOG (/opt/fog/.fogsettings)'],
                ['Ligne de commande', 'Le fichier de démarrage PXE (/tftpboot/default.ipxe)'],
                ['Interface web', 'Storage Node → default storage node'],
                ['Interface web', 'FOG Settings → FOG Configuration : fog-web-host et fog-tftp-host'],
              ]}
            />
            <p style={muted}>
              Si ces fichiers sont absents, on supprime l’utilisateur « fog » puis on relance l’installeur
              en régénérant l’autorité de certification et les clés :
            </p>
            <Code>{`sudo userdel fog
cd fogproject-stable/bin
./installfog.sh --recreate-CA --recreate-keys`}</Code>
          </FadeIn>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Compétences mobilisées</h2>
            <div className="project-tags" style={{ marginBottom: '1rem' }}>
              {competences.map((c) => (
                <span key={c} className="tech-badge">{c}</span>
              ))}
            </div>
          </FadeIn>
        </div>
      </section>
    </>
  )
}
