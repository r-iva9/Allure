export default {
  base: '/Allure/',
  title: "Allure",
  // titleTemplate: ":title ...",
  description: "Fully Typesafe DI IoC Node & Worker Framework for Luau.<br>The loader core of the Allure Ecosystem.",
  head: [
    ["link", { rel: "icon", type: 'image/svg+xml', href: "/Allure/shortlogo.svg" }]
  ],

  themeConfig: {
      logo: "/biglogo.svg",

      search: {
          provider: "local"
      },

      footer: {
          message: 'Released under the MIT License.',
      },

      // https://vitepress.dev/reference/default-theme-config
      nav: [
          { text: "Home", link: "/" },
          { text: "Documentation", link: "/course/introduction/intro" },
          { text: "API", link: "/api/types" },
      ],

      sidebar: {
          "/api/": [
              {
                  text: "API",
                  items: [
                      { text: "Types", link: "/api/types" },
                      { text: "Functions", link: "/api/functions" },
                      { text: "Errors", link: "/api/errors" },
                  ]
              }
          ],

          "/course/": [
              {
                  text: "Introduction",
                  items: [
                      { text: "What is Allure?", link: "/course/introduction/intro" },
                      { text: "Getting Started", link: "/course/introduction/gettingstarted" }
                  ]
              },
              {
                  text: "Allure",
                  items: [
                      { text: "Nodes", link: "/course/allure/node" },
                      { text: "Advanced", link: "/course/allure/advanced" },
                      { text: "Workers and multi-threading", link: "/course/allure/multithread" },
                    {
                        text: "Trees",
                        items: [
                            { text: "NodeTree", link: "/course/allure/nodetree" },
                            { text: "Multiple Trees", link: "/course/allure/nodetrees" },
                        ]
                    },
                    {
                        text: "Best Practices",
                        items: [
                            { text: "Master-Worker", link: "/course/allure/masterworker" },
                            { text: "Message Bus", link: "/course/allure/messagebus" },
                        ]
                    },
                  ]
              },
          ],
      },

      socialLinks: [
          { icon: "github", link: "https://github.com/r-iva9/Allure" }
      ]
  }
}