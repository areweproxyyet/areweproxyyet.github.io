// Lightweight renderer: fetch YAML, parse, and render project cards.
(function(){
  async function fetchYAML(path){
    const res = await fetch(path);
    if(!res.ok) throw new Error('Failed to fetch ' + path);
    return res.text();
  }

  function ghFromRepoUrl(url){
    // accept https://github.com/owner/repo
    try{
      const u = new URL(url);
      const parts = u.pathname.replace(/^\//,'').split('/');
      if(parts.length>=2) return {owner:parts[0], repo:parts[1]};
    }catch(e){}
    return null;
  }

  function badgeUrl(type, owner, repo){
    // shields.io patterns
    switch(type){
      case 'stars': return `https://img.shields.io/github/stars/${owner}/${repo}?style=flat&color=7dd3fc`;
      case 'last-release': return `https://img.shields.io/github/v/release/${owner}/${repo}?style=flat&color=60a5fa`;
      case 'last-commit': return `https://img.shields.io/github/last-commit/${owner}/${repo}?style=flat&color=86efac`;
      default: return '';
    }
  }

  function createProjectCard(p){
    const li = document.createElement('li');
    li.className = 'project-item';

    const title = document.createElement('a');
    title.href = p.repo; title.target='_blank'; title.rel='noopener noreferrer';
    title.innerHTML = `<strong>${p.name}</strong>`;

    const desc = document.createElement('p');
    desc.className = 'desc';
    desc.textContent = p.desc || '';

    const repoLink = document.createElement('a');
    repoLink.className = 'repo';
    repoLink.href = p.repo; repoLink.textContent = p.repo;

    li.appendChild(title);
    li.appendChild(desc);

    const gh = ghFromRepoUrl(p.repo);
    if(gh){
      const badges = document.createElement('div');
      badges.className = 'badges';
      const starImg = document.createElement('img');
      starImg.src = badgeUrl('stars', gh.owner, gh.repo);
      starImg.alt = 'stars';
      starImg.loading = 'lazy';
      const relImg = document.createElement('img');
      relImg.src = badgeUrl('last-release', gh.owner, gh.repo);
      relImg.alt = 'latest release';
      relImg.loading = 'lazy';
      const commitImg = document.createElement('img');
      commitImg.src = badgeUrl('last-commit', gh.owner, gh.repo);
      commitImg.alt = 'last commit';
      commitImg.loading = 'lazy';
      badges.appendChild(starImg);
      badges.appendChild(relImg);
      badges.appendChild(commitImg);
      li.appendChild(badges);
    }

    li.appendChild(repoLink);
    return li;
  }

  async function render(){
    try{
      const yamlText = await fetchYAML('/docs/data/projects.yml');
      const data = jsyaml.load(yamlText);
      const list = document.querySelector('.project-list');
      if(!list) return;
      list.innerHTML = '';
      (data.projects||[]).forEach(p=>{
        list.appendChild(createProjectCard(p));
      });
    }catch(err){
      console.error('Failed to render project list', err);
      const el = document.querySelector('.projects');
      if(el) el.insertAdjacentHTML('beforeend','<p style="color:#fbb">Failed to load project list.</p>');
    }
  }

  // run on DOMContentLoaded
  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', render);
  } else render();
})();
