local boxes = {}
local inputEnglish = "com.apple.keylayout.ABC"
local box_height_fallback = 25
local box_alpha = 0.5
local nordblue = { ["red"]=0.533,["green"]=0.753,["blue"]=0.816,["alpha"]=1 }
local box_color = hs.drawing.color.asRGB(nordblue)

-- 입력소스 변경 이벤트에 이벤트 리스너를 달아준다
hs.keycodes.inputSourceChanged(function()
    local input_source = hs.keycodes.currentSourceID()
    show_status_bar(not (input_source == inputEnglish))
end)

-- 오로라를 보여준다
function show_aurora(scr)
    local box = hs.drawing.rectangle(hs.geometry.rect(0,0,0,0))
    draw_rectangle(box, scr, 0, scr:fullFrame().w, box_color)
    table.insert(boxes, box)
end

function show_status_bar(stat)
    if stat then
        enable_show()
    else
        disable_show()
    end
end

function enable_show()
    show_status_bar(false)
    reset_boxes()
    -- 여러 개의 모니터를 사용한다면, 모든 모니터에 다 적용해준다
    hs.fnutils.each(hs.screen.allScreens(), function(scr)
        show_aurora(scr)
    end)
end

function disable_show()
    hs.fnutils.each(boxes, function(box)
        if not (box == nil) then
            box:delete()
        end
    end)
    reset_boxes()
end

function reset_boxes()
    boxes = {}
end

-- 화면에 사각형을 그려준다
function draw_rectangle(target_draw, screen, offset, width, fill_color)
    local screeng                  = screen:fullFrame()
    local screen_frame_height      = screen:frame().y
    local screen_full_frame_height = screeng.y
    local height_delta             = screen_frame_height - screen_full_frame_height
    local height                   = height_delta > 0 and height_delta or box_height_fallback

    target_draw:setSize(hs.geometry.rect(screeng.x + offset, screen_full_frame_height, width, height))
    target_draw:setTopLeft(hs.geometry.point(screeng.x + offset, screen_full_frame_height))
    target_draw:setFillColor(fill_color)
    target_draw:setFill(true)
    target_draw:setAlpha(box_alpha)
    target_draw:setLevel(hs.drawing.windowLevels.overlay)
    target_draw:setStroke(false)
    target_draw:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    target_draw:show()
end
