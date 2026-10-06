'use strict'

// Antora extension used only by default-pdf-exports.yml.
//
// The hub component's nav links to the start page of each bundled workshop. Assembler only merges
// pages that appear in the navigation of the component version it exports, so this extension grafts
// each workshop's own navigation tree beneath that link. The hub PDF then contains every workshop page
// in nav order, and the workshop navs stay the single source of truth for page order.
//
// A top-level, text-only entry that holds workshops (e.g., "Included workshops") gets Assembler's part
// role so each workshop becomes a chapter and starts on a new page in the PDF.
module.exports.register = function ({ config }) {
  const hubName = config.component ?? 'openshift-102'
  const logger = this.getLogger('pdf-bundle-nav')

  this.once('navigationBuilt', ({ contentCatalog }) => {
    const hub = contentCatalog.getComponent(hubName)
    if (!hub) return logger.warn(`Component not found: ${hubName}`)
    const startPages = new Map()
    for (const component of contentCatalog.getComponents()) {
      if (component.name === hubName) continue
      for (const componentVersion of component.versions) {
        if (componentVersion.url && componentVersion.navigation) startPages.set(componentVersion.url, componentVersion)
      }
    }
    for (const hubVersion of hub.versions) {
      const navigation = hubVersion.navigation ?? []
      const hubUrls = new Set()
      collectUrls(navigation, hubUrls)
      let grafted = 0
      walk(navigation, (entry) => {
        const workshop = entry.urlType === 'internal' && !entry.items?.length && startPages.get(entry.url)
        if (!workshop) return
        // drop links back to hub pages (e.g., the shared CLI tools page) and the duplicate start page entry
        const skip = new Set([...hubUrls, entry.url])
        entry.items = prune(structuredClone(flatten(workshop.navigation)), skip)
        entry.grafted = true
        grafted++
      })
      for (const entry of flatten(navigation)) {
        if (!entry.url && entry.items?.some((it) => it.grafted)) entry.roles = [...(entry.roles ?? []), 'part']
      }
      logger.info(`Grafted ${grafted} workshop navigation tree(s) into ${hubVersion.version}@${hubName}`)
    }
  })
}

function flatten (navigation) {
  return navigation.flatMap((list) => ('content' in list ? [list] : (list.items ?? [])))
}

function prune (items, skip) {
  return items.reduce((accum, item) => {
    if (item.items) item.items = prune(item.items, skip)
    if (item.urlType === 'internal' && skip.has(item.url)) return accum
    if (!item.url && !item.items?.length) return accum
    accum.push(item)
    return accum
  }, [])
}

function collectUrls (items, urls) {
  for (const item of items) {
    if (item.urlType === 'internal' && item.url) urls.add(item.url)
    if (item.items) collectUrls(item.items, urls)
  }
}

function walk (items, fn) {
  for (const item of items) {
    if (item.items) walk(item.items, fn)
    fn(item)
  }
}
