import { defineConfig, type DefaultTheme } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

/**
 * 主站 VitePress。项目根是 `site/`，仓库里的 `system_design/` 在源目录之外，不参与构建。
 *
 * 内容：`intro/` 系统介绍，`user_training/` 用户训练。
 * 中文为源；越南文入口挂在导航，待内容就绪后再升级为完整 locales。
 * Mermaid：```mermaid 代码块由 vitepress-plugin-mermaid 渲染为流程图。
 */
function introSidebar(): DefaultTheme.SidebarItem[] {
  return [
    {
      text: '系统介绍',
      items: [{ text: '产品概览', link: '/intro/' }],
    },
  ]
}

function userTrainingSidebar(): DefaultTheme.SidebarItem[] {
  return [
    {
      text: '总纲',
      collapsed: false,
      items: [
        { text: '训练首页', link: '/user_training/' },
        { text: '术语表', link: '/user_training/glossary.html' },
      ],
    },
    {
      text: '入门',
      collapsed: false,
      items: [
        { text: '系统入门', link: '/user_training/zh/01-getting-started/01-system-overview.html' },
        { text: '导出中心', link: '/user_training/zh/01-getting-started/02-export-center.html' },
        { text: '导入中心', link: '/user_training/zh/01-getting-started/03-import-center.html' },
      ],
    },
    {
      text: '整体流程',
      collapsed: false,
      items: [
        { text: '本节索引', link: '/user_training/zh/00-overview/' },
        { text: 'OV-01 系统流程地图', link: '/user_training/zh/00-overview/01-system-process-map.html' },
        { text: 'OV-02 销货闭环', link: '/user_training/zh/00-overview/02-order-to-cash.html' },
        { text: 'OV-03 采购闭环', link: '/user_training/zh/00-overview/03-procure-to-pay.html' },
        { text: 'OV-04 计划生产', link: '/user_training/zh/00-overview/04-plan-to-produce.html' },
        { text: 'OV-05 关账协作', link: '/user_training/zh/00-overview/05-period-close-collaboration.html' },
      ],
    },
    {
      text: '角色手册',
      collapsed: false,
      items: [
        { text: '系统管理员', link: '/user_training/zh/02-roles/role-admin.html' },
        { text: '主数据维护', link: '/user_training/zh/02-roles/role-master-data.html' },
        { text: '销售', link: '/user_training/zh/02-roles/role-sales.html' },
        { text: '采购', link: '/user_training/zh/02-roles/role-procurement.html' },
        { text: '仓储', link: '/user_training/zh/02-roles/role-warehouse.html' },
        { text: '生产计划', link: '/user_training/zh/02-roles/role-production.html' },
        { text: '财务', link: '/user_training/zh/02-roles/role-finance.html' },
      ],
    },
    {
      text: '流程剧本',
      collapsed: false,
      items: [
        { text: 'PB-01 主数据就绪', link: '/user_training/zh/03-process-playbooks/PB-01-master-data-ready.html' },
        { text: 'PB-02 销售出货', link: '/user_training/zh/03-process-playbooks/PB-02-sales-to-delivery.html' },
        { text: 'PB-03 采购入库与应付', link: '/user_training/zh/03-process-playbooks/PB-03-procure-to-pay.html' },
        { text: 'PB-04 计划到生产回馈', link: '/user_training/zh/03-process-playbooks/PB-04-mrp-to-production.html' },
        { text: 'PB-05 库存与财务关账', link: '/user_training/zh/03-process-playbooks/PB-05-period-close.html' },
        { text: 'PB-06 导出与打印', link: '/user_training/zh/03-process-playbooks/PB-06-export-and-print.html' },
        { text: 'PB-07 导入中心', link: '/user_training/zh/03-process-playbooks/PB-07-import-center.html' },
        { text: 'PB-08 委外闭环', link: '/user_training/zh/03-process-playbooks/PB-08-outsource-loop.html' },
        { text: 'PB-09 库存盘点', link: '/user_training/zh/03-process-playbooks/PB-09-physical-inventory.html' },
        { text: 'PB-10 销货到收款', link: '/user_training/zh/03-process-playbooks/PB-10-order-to-cash.html' },
      ],
    },
    {
      text: '模块速查',
      collapsed: true,
      items: [
        { text: '速查索引', link: '/user_training/zh/04-module-quickref/' },
        { text: 'ADM 系统管理', link: '/user_training/zh/04-module-quickref/adm.html' },
        { text: 'BASIS 基础资料', link: '/user_training/zh/04-module-quickref/basis.html' },
        { text: 'MM 物料', link: '/user_training/zh/04-module-quickref/mm.html' },
        { text: 'SD 销售', link: '/user_training/zh/04-module-quickref/sd.html' },
        { text: 'SCM 采购', link: '/user_training/zh/04-module-quickref/scm.html' },
        { text: 'WM 仓储', link: '/user_training/zh/04-module-quickref/wm.html' },
        { text: 'PP 生产计划', link: '/user_training/zh/04-module-quickref/pp.html' },
        { text: 'FI 财务', link: '/user_training/zh/04-module-quickref/fi.html' },
        { text: 'RPT 报表中心', link: '/user_training/zh/04-module-quickref/report.html' },
      ],
    },
    {
      text: '运维开通',
      collapsed: true,
      items: [
        { text: '菜单与权限', link: '/user_training/zh/05-admin-ops/01-menu-and-permission.html' },
        { text: '导入导出上线检查清单', link: '/user_training/zh/05-admin-ops/02-export-go-live-checklist.html' },
      ],
    },
    {
      text: '越南文',
      collapsed: true,
      items: [{ text: '进度说明', link: '/user_training/vi/' }],
    },
  ]
}

export default withMermaid({
  ...defineConfig({
    title: 'Lychee ERP',
    description: 'Lychee ERP 系统介绍与用户训练',
    lang: 'zh-CN',
    // 保留 .html，页面地址与 OSS 对象键一致。目录首页仍用结尾斜杠。
    // README 与截图目录不作为页面。写作约定只给仓库内阅读，不发布。
    srcExclude: ['README.md', '**/assets/**', 'user_training/00-conventions.md'],

    head: [['meta', { name: 'theme-color', content: '#1a5f4a' }]],

    // pnpm 下预构建 mermaid，避免开发态 ambiguous export
    vite: {
      optimizeDeps: {
        include: ['mermaid'],
      },
    },

    themeConfig: {
      logo: undefined,
      siteTitle: 'Lychee',

      nav: [
        { text: '首页', link: '/' },
        { text: '系统介绍', link: '/intro/', activeMatch: '/intro/' },
        { text: '用户训练', link: '/user_training/', activeMatch: '/user_training/' },
        { text: '术语表', link: '/user_training/glossary.html' },
        { text: 'Tiếng Việt', link: '/user_training/vi/' },
      ],

      sidebar: {
        '/intro/': introSidebar(),
        '/user_training/': userTrainingSidebar(),
      },

      search: {
        provider: 'local',
        options: {
          locales: {
            root: {
              translations: {
                button: { buttonText: '搜索', buttonAriaLabel: '搜索文档' },
                modal: {
                  noResultsText: '没有找到相关结果',
                  resetButtonTitle: '清除查询',
                  footer: {
                    selectText: '选择',
                    navigateText: '切换',
                    closeText: '关闭',
                  },
                },
              },
            },
          },
        },
      },

      outline: {
        label: '本页目录',
        level: [2, 3],
      },

      docFooter: {
        prev: '上一页',
        next: '下一页',
      },

      returnToTopLabel: '回到顶部',
      sidebarMenuLabel: '菜单',
      darkModeSwitchLabel: '主题',
      lightModeSwitchTitle: '切换到浅色',
      darkModeSwitchTitle: '切换到深色',

      socialLinks: [],
    },
  }),
  // Mermaid 默认主题；深色模式由插件按 body.dark 切换
  mermaid: {
    theme: 'base',
    flowchart: {
      htmlLabels: true,
      curve: 'basis',
    },
  },
})
