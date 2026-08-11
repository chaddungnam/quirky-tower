(() => {
  const sections = [...document.querySelectorAll('main > section')];
  const tocShell = document.querySelector('#toc .shell');
  const search = document.querySelector('#search');
  const count = document.querySelector('#search-count');
  const details = [...document.querySelectorAll('details')];

  for (const section of sections) {
    const heading = section.querySelector('h2');
    if (!heading) continue;
    const link = document.createElement('a');
    link.href = `#${section.id}`;
    link.textContent = heading.textContent;
    link.dataset.target = section.id;
    tocShell.append(link);

    const copy = document.createElement('button');
    copy.type = 'button';
    copy.className = 'anchor-copy';
    copy.title = '이 섹션 링크 복사';
    copy.setAttribute('aria-label', `${heading.textContent} 링크 복사`);
    copy.setAttribute('aria-live', 'polite');
    copy.textContent = '#';
    copy.addEventListener('click', async () => {
      const url = `${location.href.split('#')[0]}#${section.id}`;
      try {
        await navigator.clipboard.writeText(url);
        copy.textContent = '✓';
      } catch (_) {
        location.hash = section.id;
        copy.textContent = '↗';
      }
      setTimeout(() => { copy.textContent = '#'; }, 1200);
    });
    section.querySelector('.section-head')?.append(copy);
  }

  const tocLinks = [...tocShell.querySelectorAll('a')];
  const setActive = id => {
    for (const link of tocLinks) {
      const active = link.dataset.target === id;
      link.classList.toggle('active', active);
      if (active) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    }
  };
  const observer = new IntersectionObserver(entries => {
    const visible = entries.filter(entry => entry.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
    if (visible[0]) setActive(visible[0].target.id);
  }, { rootMargin: '-28% 0px -62% 0px', threshold: 0 });
  sections.forEach(section => observer.observe(section));

  const normalize = value => value.normalize('NFKC').toLocaleLowerCase();
  const applySearch = () => {
    const query = normalize(search.value.trim());
    let shown = 0;
    for (const section of sections) {
      const haystack = normalize([
        section.textContent,
        section.dataset.source || '',
        section.dataset.decision || '',
        section.dataset.feature || ''
      ].join(' '));
      const match = !query || haystack.includes(query);
      section.classList.toggle('search-hidden', !match);
      if (query && match) {
        for (const item of section.querySelectorAll('details')) {
          if (normalize(item.textContent).includes(query)) item.open = true;
        }
      }
      const link = tocLinks.find(item => item.dataset.target === section.id);
      link?.classList.toggle('search-hidden', !match);
      if (match) shown += 1;
    }
    count.textContent = query ? `${shown}/${sections.length} 섹션` : '전체 표시';
  };
  search.addEventListener('input', applySearch);
  search.addEventListener('keydown', event => {
    if (event.key === 'Escape') {
      search.value = '';
      applySearch();
      search.blur();
    }
  });

  document.querySelector('#expand-all').addEventListener('click', () => details.forEach(item => { item.open = true; }));
  document.querySelector('#collapse-all').addEventListener('click', () => details.forEach(item => { item.open = false; }));

  let printState = [];
  addEventListener('beforeprint', () => {
    printState = details.map(item => item.open);
    details.forEach(item => { item.open = true; });
  });
  addEventListener('afterprint', () => details.forEach((item, index) => { item.open = printState[index]; }));

  if (location.hash) {
    const target = document.querySelector(location.hash);
    target?.closest('details')?.setAttribute('open', '');
  }
})();
