import Link from 'next/link'
import FadeIn from '@/components/FadeIn'
import { muted, Sub, Table, Figure, Bullets } from '@/components/ProjetDoc'

const competences = [
  'Proxmox VE', 'pfSense', 'VLAN', 'Règles de pare-feu', 'Windows Server 2022', 'Active Directory',
  'DNS / GPO', 'LDAP', 'Debian 13', 'Docker Compose', 'GLPI', 'Nextcloud', 'Portainer', 'Squid', 'Traefik',
]

export default function InfraServicesPage() {
  return (
    <>
      <div className="page-hero">
        <div className="container">
          <p className="page-hero-label">Projet / Réseaux & Sécurité</p>
          <h1>Infrastructure de services sécurisée</h1>
          <p>
            pfSense, Active Directory, GLPI, Nextcloud et proxy Squid sur Proxmox VE, avec un réseau
            segmenté en trois VLAN.
          </p>
        </div>
      </div>

      <section className="section">
        <div className="container" style={{ maxWidth: '900px' }}>
          <Link href="/projets" className="btn btn-outline" style={{ fontSize: '0.65rem', padding: '0.4rem 0.75rem' }}>
            ← Retour aux projets
          </Link>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '2.5rem' }}>Contexte et objectifs</h2>
            <p style={muted}>
              Déployer sur un hôte Proxmox VE un réseau d’entreprise complet : un pare-feu pfSense qui
              segmente et filtre les flux, un annuaire Active Directory, et des services applicatifs
              (gestion de parc, partage de fichiers, proxy) dont l’authentification est centralisée par LDAP.
            </p>
            <Bullets
              items={[
                'Segmenter le réseau en trois VLAN (infrastructure, services, clients) derrière pfSense.',
                'Fournir un annuaire et des services de domaine : AD DS, DNS, GPO, partages réseau.',
                'Héberger GLPI, Nextcloud et Portainer avec Docker, et un proxy Squid.',
                'Authentifier les utilisateurs de GLPI et de Nextcloud grâce à l’annuaire Active Directory (LDAP).',
              ]}
            />
          </FadeIn>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Architecture</h2>
            <Figure
              src="/projets/services-vlan.svg"
              alt="Schéma : pfSense et trois VLAN (infrastructure, services, clients) sur un hôte Proxmox"
              caption="Schéma simplifié et anonymisé : adresses fictives."
            />
            <Table
              head={['Machine', 'Réseau', 'Rôle']}
              rows={[
                ['Hôte Proxmox VE', 'Réseau physique', 'Hyperviseur qui héberge toutes les VM'],
                ['Proxmox Backup Server', 'Réseau physique', 'Sauvegarde des VM'],
                ['pfSense', 'WAN, LAN et 3 VLAN', 'Pare-feu et routeur (passerelle .254 de chaque VLAN)'],
                ['Windows Server 2022', 'VLAN 10 — Infrastructure', 'AD DS, DNS, GPO, partages réseau'],
                ['Debian 13', 'VLAN 20 — Services', 'GLPI, Nextcloud, Portainer, SSH, proxy Squid'],
                ['Windows 10', 'VLAN 30 — Clients (DHCP)', 'Poste client du domaine'],
              ]}
            />
          </FadeIn>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Configuration du pare-feu pfSense</h2>
            <Bullets
              items={[
                'Une interface par VLAN, avec la passerelle de chaque réseau portée par pfSense.',
                'Règles de filtrage créées pour chaque VLAN : sans elles, aucun flux ne circule entre les réseaux.',
                'Règle sur l’interface WAN pour accéder à l’interface d’administration depuis le réseau physique.',
                'Ouverture ciblée des flux nécessaires, par exemple SMB depuis les clients vers le VLAN infrastructure pour les lecteurs réseau.',
              ]}
            />
          </FadeIn>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Services déployés</h2>
            <Table
              head={['Service', 'Mise en œuvre']}
              rows={[
                ['Active Directory', 'Windows Server 2022 : AD DS, DNS, GPO, partages. Création du domaine sans difficulté.'],
                ['GLPI', 'Docker Compose sur Debian 13, authentification LDAP, inventaire du parc avec l’agent GLPI.'],
                ['Nextcloud', 'Docker Compose derrière le reverse proxy Traefik, authentification LDAP.'],
                ['Portainer', 'Interface de gestion des conteneurs Docker.'],
                ['Squid', 'Proxy web : mise en place simple, règles faciles à ajouter.'],
              ]}
            />
          </FadeIn>

          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Difficultés rencontrées et solutions</h2>
            <p style={muted}>Chaque problème a été diagnostiqué puis documenté, voici les principaux.</p>
            <Sub>Réseau et systèmes</Sub>
            <Table
              head={['Problème', 'Cause', 'Solution']}
              rows={[
                ['pfSense inaccessible depuis le WAN', 'Règle NAT inutile et option « Block private networks » active', 'Suppression du NAT, option décochée, règle de pare-feu WAN créée'],
                ['VLAN sans connectivité', 'Aucune règle de pare-feu sur les VLAN', 'Création des règles pour chaque VLAN'],
                ['Debian sans adresse IP', 'Mot-clé incorrect dans /etc/network/interfaces et interface éteinte', 'Correction du fichier puis activation de l’interface'],
                ['Windows Server en DHCP, puis perte du réseau', 'Configuration IP automatique, puis mauvais mot-clé dans la configuration statique', 'IP statique correctement configurée'],
                ['Lecteurs réseau déconnectés', 'Le DNS ne résout pas le nom du serveur depuis le VLAN clients', 'Autorisation du port SMB vers le VLAN infrastructure'],
              ]}
            />
            <Sub>Services applicatifs</Sub>
            <Bullets
              items={[
                'Nextcloud : utiliser l’image Docker standard plutôt que l’image All-in-One ; suivre un tutoriel d’installation derrière Traefik en l’adaptant (le fichier .env n’est pas nécessaire) ; ranger le projet dans un dossier dédié (compose/nextcloud).',
                'GLPI : difficultés avec le script de remontée LDAP vers le serveur et avec la remontée d’inventaire.',
                'Squid : aucune difficulté.',
                'Windows 10/11 et Windows Server 2022/2025 : ne démarrent pas sur un processeur à l’architecture trop ancienne.',
              ]}
            />
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
