Array.from(document.querySelectorAll('tr')).map(tr => {
    const tds = tr.querySelectorAll('td');
    if (tds.length >= 2) {
        const link = tds[0].querySelector('a');
        if (link && link.textContent !== '../') {
            return {
                name: link.textContent,
                size: tds[1]?.textContent?.trim() || '-',
                date: tds[2]?.textContent?.trim() || '-'
            };
        }
    }
    return null;
}).filter(f => f);
