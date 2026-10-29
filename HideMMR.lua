local ADDON_NAME = ...

-- Rated brackets in ConquestFrame whose rating should be hidden
local BRACKETS = {
    "RatedSoloShuffle",
    "Arena2v2",
    "Arena3v3",
}

-- Hide a region and keep it hidden even if Blizzard code calls Show/SetShown later
local function KeepHidden(region)
    if not region or region.__HideMMRHidden then
        return
    end
    region.__HideMMRHidden = true

    hooksecurefunc(region, "Show", region.Hide)
    hooksecurefunc(region, "SetShown", function(self, shown)
        if shown then
            self:Hide()
        end
    end)
    region:Hide()
end

local function HideConquestRatings()
    if not ConquestFrame then
        return
    end

    for _, key in ipairs(BRACKETS) do
        local button = ConquestFrame[key]
        if button then
            KeepHidden(button.CurrentRating)
            if button.Tier then
                KeepHidden(button.Tier.Ranking)
            end
        end
    end
end

-- ConquestFrame lives in the load-on-demand Blizzard_PVPUI addon
EventUtil.ContinueOnAddOnLoaded("Blizzard_PVPUI", function()
    HideConquestRatings()
    -- Buttons may be (re)populated on show, so re-apply just in case
    ConquestFrame:HookScript("OnShow", HideConquestRatings)
end)

-- In-match scoreboard and end-of-match results (MMR text)
-- Scoreboard uses PascalCase keys, results frame uses camelCase
local function HideMatchFrameMMR(frame)
    if not frame then
        return
    end

    local content = frame.Content or frame.content
    local tabContainer = content and (content.TabContainer or content.tabContainer)
    if tabContainer then
        KeepHidden(tabContainer.MatchmakingText or tabContainer.matchmakingText)
    end
end

-- Score table columns (dataProviderKey of PVPCellStringTemplate cells)
local HIDDEN_CELL_KEYS = {
    prematchMMR = true,
    rating = true,
    ratingChange = true,
}

-- Score table headers (sortType of PVPHeaderStringTemplate headers)
local HIDDEN_HEADER_SORT_TYPES = {
    mmrPre = true,
    bgratingPre = true,
    bgratingPost = true,
    bgratingChange = true,
}

-- Table cells are pooled and recycled by the ScrollBox, so the text is blanked
-- every time a cell gets populated. The hooks must be installed on the mixins
-- before any cell is created, since XML mixins copy functions at creation time.
local function HookScoreTable()
    hooksecurefunc(PVPCellStringMixin, "Populate", function(self)
        if HIDDEN_CELL_KEYS[self.dataProviderKey] then
            self.text:SetText("")
        end
    end)

    -- "New rating" column (rating + ratingChange)
    hooksecurefunc(PVPNewRatingMixin, "Populate", function(self)
        self.text:SetText("")
    end)

    hooksecurefunc(PVPHeaderStringMixin, "Init", function(self, textID, textAlignment, sortType)
        if HIDDEN_HEADER_SORT_TYPES[sortType] then
            self.text:SetText("")
        end
    end)
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_PVPMatch", function()
    HookScoreTable()
    HideMatchFrameMMR(PVPMatchScoreboard)
    HideMatchFrameMMR(PVPMatchResults)
    -- "+N rating" block with tier icon and MMR tooltip; layout skips hidden frames
    KeepHidden(PVPMatchResults.progressContainer.rating)
end)
