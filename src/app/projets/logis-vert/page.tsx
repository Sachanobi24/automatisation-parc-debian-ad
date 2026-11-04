import Link from 'next/link'
import FadeIn from '@/components/FadeIn'
import { muted, Sub, Table, Figure, Bullets } from '@/components/ProjetDoc'

const competences = [
  'Proxmox VE', 'ProxCenter', 'Cluster & HA', 'Ceph (RBD, CephFS)', 'Proxmox Backup Server',
  'pfSense', 'CARP / pfsync', 'VLAN', 'LACP / bonding', 'Docker', 'nginx', 'Python', 'Zabbix',
]

export default function LogisVertPage() {
  return (
    <>
      <div className="page-hero">
        <div className="container">
          <p className="page-hero-label">Projet / Infrastructure</p>
          <h1>Logis Vert</h1>
          <p>
            Infrastructure de virtualisation haute disponibilité : cluster Proxmox, stockage Ceph,
            sauvegardes centralisées, pare-feu redondants et supervision.
          </p>
        </div>
      </div>

      <section className="section">
        <div className="container" style={{ maxWidth: '900px' }}>
          <Link href="/projets" className="btn btn-outline" style={{ fontSize: '0.65rem', padding: '0.4rem 0.75rem' }}>
            ← Retour aux projets
          </Link>

          {/* ---------- Contexte ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '2.5rem' }}>Contexte et objectifs</h2>
            <p style={muted}>
              Le projet consiste à mettre en place, dans une baie du laboratoire, une infrastructure de
              virtualisation tolérante aux pannes, puis à la documenter : architecture, procédures de
              sauvegarde et de restauration, supervision.
            </p>
            <Bullets
              items={[
                'Mutualiser trois serveurs dans un cluster Proxmox VE (migration de VM, haute disponibilité).',
                'Fournir un stockage partagé, distribué et redondant pour les machines virtuelles (Ceph).',
                'Assurer la continuité du pare-feu avec deux pfSense en haute disponibilité (CARP).',
                'Sauvegarder les VM et savoir les restaurer (Proxmox Backup Server).',
                'Centraliser la gestion avec un serveur ProxCenter, et l’accès aux services avec des tableaux de bord.',
              ]}
            />
          </FadeIn>

          {/* ---------- Architecture ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Architecture générale</h2>
            <Figure
              src="/logis-vert/architecture.svg"
              alt="Schéma de l’architecture : réseau de management, cluster Proxmox, réseau Ceph dédié, sauvegarde et ISO"
              caption="Schéma simplifié et anonymisé : les adresses et noms réels ont été retirés."
            />
          </FadeIn>

          {/* ---------- Cluster + Ceph ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Cluster Proxmox VE et stockage Ceph</h2>
            <p style={muted}>
              Trois nœuds Proxmox VE forment un cluster : gestion centralisée, migration des VM entre
              nœuds et haute disponibilité. Le stockage est mutualisé grâce à Ceph, qui réplique les
              données sur les disques des trois serveurs.
            </p>

            <Sub>Serveur de management : ProxCenter</Sub>
            <p style={muted}>
              Un serveur dédié, <strong>ProxCenter</strong>, est rattaché au VLAN de management. Il fournit
              une interface de gestion et de supervision centralisée de l’infrastructure : un point d’entrée
              unique pour suivre l’ensemble des hôtes plutôt que de se connecter à chacun individuellement.
            </p>

            <Sub>Réseau des nœuds</Sub>
            <Table
              head={['Interface', 'Usage']}
              rows={[
                ['bond0 (2 cartes, balance-rr)', 'Réseau de management (VLAN 40) via le bridge vmbr0'],
                ['3ᵉ carte dédiée', 'Réseau Ceph et communication du cluster (corosync), isolés du management'],
              ]}
            />

            <Sub>Stockage distribué Ceph</Sub>
            <Table
              head={['Composant', 'Configuration']}
              rows={[
                ['Stockage', 'stockage_ceph (RBD), partagé par les 3 nœuds'],
                ['Moniteurs (MON)', '3, tous en quorum'],
                ['Managers (MGR)', '3, dont 1 actif et 2 en attente'],
                ['OSD', '3 (un par nœud) : 1 disque HDD et 2 SSD'],
                ['CephFS', 'Volume de secours pour les images ISO'],
              ]}
            />
            <p style={muted}>
              Les images ISO de déploiement sont hébergées sur un NAS situé sur un autre sous-réseau ;
              le routage inter-VLAN doit donc fonctionner pour que les nœuds y accèdent. CephFS prend
              le relais si le NAS est indisponible.
            </p>
          </FadeIn>

          {/* ---------- Réseau + pfSense ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Réseau et pare-feu en haute disponibilité</h2>
            <p style={muted}>
              Les équipements de la baie sont rattachés au VLAN 40 de management : ports 1 à 16 du
              switch en <em>untagged</em>, et deux liens fibre en trunk agrégés en LACP. Le filtrage et
              le routage entre VLAN sont assurés par deux VM pfSense (MASTER et BACKUP) qui se partagent
              une adresse virtuelle grâce au protocole CARP.
            </p>
            <Figure
              src="/logis-vert/pfsense-ha.svg"
              alt="Schéma de la paire de pare-feu pfSense en haute disponibilité et des VLAN associés"
              caption="Paire pfSense (CARP + pfsync) sur un hôte Proxmox : adresses fictives."
            />
            <Table
              head={['VLAN', 'Usage', 'Machines']}
              rows={[
                ['10', 'Services', 'Debian (Docker), Zabbix'],
                ['20', 'Serveurs', 'Deux contrôleurs de domaine'],
                ['30', 'Clients', 'Poste Windows 10'],
                ['40', 'Administration', 'Poste d’administration'],
                ['99', 'Synchronisation pfsync', 'Réservé aux deux pare-feux'],
              ]}
            />
            <p style={muted}>
              L’état des connexions et la configuration sont répliqués du MASTER vers le BACKUP sur le
              VLAN 99 dédié : en cas de panne du MASTER, le BACKUP prend automatiquement le relais.
            </p>
            <Sub>Points de vigilance documentés</Sub>
            <Bullets
              items={[
                'Contrôler régulièrement le statut CARP (MASTER / BACKUP) depuis le tableau de bord pfSense.',
                'Ne jamais brancher d’équipement tiers sur le VLAN 99.',
                'Vérifier que le trunk du switch autorise bien les VLAN 10, 20, 30 et 40.',
                'Tester périodiquement un basculement manuel pour valider la continuité de service.',
              ]}
            />
          </FadeIn>

          {/* ---------- Sauvegarde ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Sauvegarde avec Proxmox Backup Server</h2>
            <p style={muted}>
              Un serveur Proxmox Backup Server, rattaché aux trois nœuds, reçoit les sauvegardes
              planifiées. Elles sont dédupliquées et élaguées automatiquement selon la politique de
              rétention.
            </p>
            <Table
              head={['Élément', 'Valeur']}
              rows={[
                ['Mode de sauvegarde', 'Snapshot'],
                ['Planification', 'Tous les jours à 20 h'],
                ['Rétention', 'Dernière sauvegarde + 1 quotidienne + 1 hebdomadaire'],
                ['VM sauvegardée', 'VM Debian (ID 100)'],
              ]}
            />
            <Sub>Procédures de restauration rédigées</Sub>
            <Bullets
              items={[
                'Depuis l’interface Proxmox VE : choix du stockage PBS, de la sauvegarde, du nœud et du stockage de destination (option « Unique » pour ne pas écraser la VM d’origine).',
                'Depuis l’interface du PBS : sélection du groupe de sauvegarde puis du snapshot à restaurer.',
                'Restauration d’un seul fichier (File Restore) : exploration du disque monté virtuellement et téléchargement des éléments voulus.',
                'Vérification après restauration : démarrage de la VM, réseau, données, journaux système, absence de conflit d’ID ou d’IP.',
              ]}
            />
          </FadeIn>

          {/* ---------- Supervision / dashboards ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Supervision et tableaux de bord</h2>
            <p style={muted}>
              Deux tableaux de bord tournent sur une VM Debian avec Docker pour regrouper les accès aux
              services de l’infrastructure (Proxmox, pfSense, PBS, Zabbix…).
            </p>
            <Sub>Homepage</Sub>
            <p style={muted}>
              Tableau de bord open source configuré par fichiers YAML : cartes de services avec
              surveillance de disponibilité, barre de liens, fond d’écran local, protégé par une
              authentification Caddy.
            </p>
            <Sub>Logisvert : tableau de bord développé sur mesure</Sub>
            <Bullets
              items={[
                'Page unique avec une tuile par groupe, un voyant par serveur (en ligne, hors ligne, non surveillé), un compteur global et une recherche.',
                'Éditeur intégré à la page pour ajouter, renommer ou supprimer des serveurs sans passer par un terminal.',
                'Surveillance par un script Python lancé chaque minute par cron ; la page relit l’état toutes les 30 secondes.',
                'Architecture en deux conteneurs : nginx et un petit service d’authentification en Python.',
                'Authentification : mots de passe hachés (PBKDF2-SHA256, 200 000 itérations), cookie de session signé de 12 h (HttpOnly, SameSite=Lax), blocage de l’IP 60 secondes après 5 échecs.',
                'Personnalisation : vrais logos des services et thème Dragon Ball.',
              ]}
            />
          </FadeIn>

          {/* ---------- Compétences ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Compétences mobilisées</h2>
            <div className="project-tags" style={{ marginBottom: '1rem' }}>
              {competences.map((c) => (
                <span key={c} className="tech-badge">{c}</span>
              ))}
            </div>
          </FadeIn>

          {/* ---------- Limites ---------- */}
          <FadeIn>
            <h2 className="section-title" style={{ marginTop: '3rem' }}>Limites identifiées et améliorations</h2>
            <Bullets
              items={[
                'Un seul OSD Ceph par nœud, avec des disques de classes différentes (1 HDD, 2 SSD) : la résilience dépend du facteur de réplication. Homogénéiser les disques et ajuster la règle de placement CRUSH l’améliorerait.',
                'Le job de sauvegarde documenté ne couvre qu’une VM et la rétention reste minimale : à étendre à l’ensemble des VM critiques.',
                'La connexion aux tableaux de bord se fait en HTTP, acceptable en laboratoire isolé ; en production, passer par un reverse proxy avec HTTPS.',
              ]}
            />
          </FadeIn>
        </div>
      </section>
    </>
  )
}
