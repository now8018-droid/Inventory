Template = Template or {}

--- @type table<string, string>
Template.color = {
    [0] = {
        Background = '',
        BackgroundHover = 'radial-gradient(rgba(28, 146, 210, .3), rgba(28, 146, 210, .0))',
        -- Border = 'rgba(255,255,255, .1)',
        BorderHover = 'rgba(255,255,255, .1)',
        IconBackdrop = '',
        Color = {
            Label = '#1C92D2',
            IconFavorite = '#1C92D2',
        }
    },
    [1] = {
        Background = 'radial-gradient(rgba(250,166,31,.2), rgba(250,166,31,.0))',
        BackgroundHover = 'radial-gradient(rgba(250,166,31,.3), rgba(250,166,31,.0))',
        Border = 'rgba(250,166,31,.1)',
        BorderHover = 'rgba(250,166,31,.2)',
        IconBackdrop = 'icon',
        Color = {
            Label = '#faa61f',
            IconFavorite = '#faa61f',
        }
    },
    [2] = {
        Background = 'radial-gradient(rgba(250,166,31,.2), rgba(250,166,31,.0))',
        BackgroundHover = 'radial-gradient(rgba(250,166,31,.3), rgba(250,166,31,.0))',
        Border = 'rgba(250,166,31,.1)',
        BorderHover = 'rgba(250,166,31,.2)',
        IconBackdrop = 'icon',
        Color = {
            Label = '#faa61f',
            IconFavorite = '#faa61f',
        }
    },
    [3] = {
        Background = 'radial-gradient(rgba(255, 208, 8,.3), rgba(255, 208, 8,.0))',
        BackgroundHover = 'radial-gradient(rgba(255, 208, 8,.3), rgba(255, 208, 8,.0))',
        Border = 'rgba(255,208,8,.1)',
        BorderHover = 'rgba(255,208,8,.2)',
        IconBackdrop = 'icon',
        Color = {
            Label = '#FA1F39',
            IconFavorite = '#FA1F39',
        }
    },
    [4] = {
        Background = 'radial-gradient(rgba(226,15,15,.3), rgba(226,15,15,.0))',
        BackgroundHover = 'radial-gradient(rgba(226,15,15,.3), rgba(226,15,15,.0))',
        Border = 'rgba(226,15,15,.1)',
        BorderHover = 'rgba(226,15,15,.2)',
        IconBackdrop = 'icon',
        Color = {
            Label = '#FA1F39',
            IconFavorite = '#FA1F39',
        }
    },
    [5] = {
        Background = 'radial-gradient(to bottom, rgba(255,255,255,0.4) 10.21%, rgba(238,197,91,0.3) 100%)',
        BackgroundHover = 'radial-gradient(to bottom, rgba(255,255,255,0.4) 10.21%, rgba(238,197,91,0.3) 100%)',
        Border = 'rgba(226,15,15,.1)',
        BorderHover = 'rgba(226,15,15,.2)',
        IconBackdrop = 'icon',
        Color = {
            Label = '#FA1F39',
            IconFavorite = '#FA1F39',
        }
    },
}

--- @type table<string, number>
Template.items = {
    -- water = 1,
    -- phone = 2,
    -- WEAPON_BOTTLE = 4,
    -- gang_card = 5,
    voltvip = 2,
}
