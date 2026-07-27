# Un monstre tel que vu par une équipe. Si l'équipe du spectateur est enfumée (fumigène),
# les PV sont masqués (hp/max_hp/percent à nil, masked: true) — le front affiche « ??? ».
# L'état (dessin du monstre) reste visible : on ne peut pas cacher la bête elle-même.
class MonsterPresenter
  def self.call(monster, viewer_team: nil)
    return nil unless monster

    base = { name: monster.name, slug: monster.slug, state: monster.state, protected: monster.protected? }
    if viewer_team&.blinded?
      base.merge(hp: nil, max_hp: nil, percent: nil, masked: true)
    else
      base.merge(hp: monster.hp, max_hp: monster.max_hp, percent: monster.hp_percent, masked: false)
    end
  end
end
