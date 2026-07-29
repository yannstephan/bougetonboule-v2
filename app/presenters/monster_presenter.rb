# Un monstre tel que vu par une équipe. Un fumigène adverse peut masquer les PV d'UN monstre
# précis (hp/max_hp/percent à nil, masked: true) — le front affiche « ??? ». L'état (dessin du
# monstre) reste visible : on ne peut pas cacher la bête elle-même.
class MonsterPresenter
  def self.call(monster, viewer_team: nil)
    return nil unless monster

    base = { name: monster.name, slug: monster.slug, state: monster.state, protected: monster.protected? }
    if viewer_team&.smoke_masks?(monster.team_id)
      base.merge(hp: nil, max_hp: nil, percent: nil, masked: true)
    else
      base.merge(hp: monster.hp, max_hp: monster.max_hp, percent: monster.hp_percent, masked: false)
    end
  end
end
